// supabase/functions/scrape-nfce/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS'
};

const BROWSERLESS_API_KEY = Deno.env.get("BROWSERLESS_API_KEY");
const BROWSERLESS_URL = `https://production-sfo.browserless.io/function?token=${BROWSERLESS_API_KEY}`;

function parseDate(dateString: string | null) {
  if (!dateString) return null;
  const parts = dateString.match(/(\d{2})\/(\d{2})\/(\d{4})\s+(\d{2}):(\d{2}):(\d{2})/);
  if (!parts) return null;
  return `${parts[3]}-${parts[2]}-${parts[1]}T${parts[4]}:${parts[5]}:${parts[6]}`;
}

function cleanUpData(scraped: any) {
  const mercado = {
    nome: scraped.mercado.nome,
    cnpj: scraped.mercado.cnpj?.replace(/\D/g, ''),
    endereco: scraped.mercado.endereco?.replace(/\s+/g, ' ').trim()
  };

  const produtos = scraped.produtos.map((p: any) => ({
    codigo: p.codigo?.replace('(Código:', '').replace(')', '').trim(),
    nome: p.nome?.trim(),
    quantidade: parseFloat(p.qtd?.replace('Qtde.:', '').replace(',', '.').trim() || "0"),
    unidade: p.unidade?.replace('UN:', '').trim(),
    valor_unitario: parseFloat(p.valor_unitario?.replace('Vl. Unit.:', '').replace(',', '.').trim() || "0"),
    valor_total_item: parseFloat(p.valor_total?.replace(',', '.') || "0")
  }));

  const totais = {
    qtd_itens: parseInt(scraped.totais.qtdItens, 10),
    valor_total: parseFloat(scraped.totais.valorPagar?.replace(',', '.') || "0")
  };

  return { mercado, produtos, totais, data_emissao: scraped.data_emissao };
}

const puppeteerScript = `
  export default async ({ page, context }) => {
    const { url, chave_acesso } = context;
    
    console.log('1. Iniciando navegação...');
    await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36');
    
    // domcontentloaded é muito mais rápido que networkidle0
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 20000 });
    
    console.log('2. Buscando campo de entrada...');
    const inputSelector = 'input[id$="chaveAcesso"], input[name$="chaveAcesso"], #chaveAcesso';
    await page.waitForSelector(inputSelector, { timeout: 10000 });
    
    console.log('3. Digitando chave...');
    await page.type(inputSelector, chave_acesso);
    
    console.log('4. Clicando no botão de consulta...');
    const btnSelector = 'input[type="submit"], button[type="submit"], .btn-primary';
    await page.click(btnSelector);

    console.log('5. Aguardando tabela de resultados...');
    try {
      await page.waitForSelector('#tabResult', { timeout: 20000 });
    } catch (e) {
      console.log('5.1 Tabela não encontrada, verificando erros na página...');
      const errorMsg = await page.evaluate(() => {
        const el = document.querySelector('.rf-msgs-sum') || document.querySelector('.textoErro') || document.querySelector('.alert-danger');
        return el ? el.textContent.trim() : null;
      });
      if (errorMsg) throw new Error(errorMsg);
      
      const screenshot = await page.screenshot({ encoding: 'base64' });
      console.error('SCREENSHOT EM FALHA:', screenshot);
      throw new Error('Timeout aguardando #tabResult. Verifique o log de screenshot.');
    }

    console.log('6. Extraindo dados da página...');
    return await page.evaluate(() => {
        const getText = (root, selector) => root.querySelector(selector)?.textContent.trim() || null;
        const mercadoElements = Array.from(document.querySelectorAll('.txtCenter > .text'));
        const cnpjElement = mercadoElements.find(el => el.textContent.includes('CNPJ:'));
        const enderecoElement = mercadoElements.find(el => !el.textContent.includes('CNPJ:'));
        
        return {
            mercado: {
                nome: getText(document, '#u20') || getText(document, '.txtFantasia') || 'Mercado Desconhecido',
                cnpj: cnpjElement ? cnpjElement.textContent.trim() : null,
                endereco: enderecoElement ? enderecoElement.textContent.trim() : null,
            },
            produtos: Array.from(document.querySelectorAll('#tabResult > tbody > tr')).map(row => ({
                nome: getText(row, 'span.txtTit'),
                codigo: getText(row, 'span.RCod'),
                qtd: getText(row, 'span.Rqtd'),
                unidade: getText(row, 'span.RUN'),
                valor_unitario: getText(row, 'span.RvlUnit'),
                valor_total: getText(row, 'span.valor'),
            })),
            totais: {
                qtdItens: getText(document, '#totalNota > div:nth-child(1) > span.totalNumb'),
                valorPagar: getText(document, '#totalNota > div:nth-child(2) > span.totalNumb'),
            },
            data_emissao: (() => {
                const strongs = Array.from(document.querySelectorAll('#infos strong'));
                const label = strongs.find(s => s.textContent.trim() === 'Emissão:');
                if (label && label.nextSibling) {
                  const m = label.nextSibling.textContent.match(/(\\d{2}\\/\\d{2}\\/\\d{4}\\s+\\d{2}:\\d{2}:\\d{2})/);
                  return m ? m[1] : null;
                }
                return null;
            })()
        };
    });
  }
`;

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  
  try {
    const { chave_acesso } = await req.json();
    if (!chave_acesso) throw new Error("Chave de acesso é obrigatória");

    const authHeader = req.headers.get('Authorization');
    const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
      global: { headers: { Authorization: authHeader! } }
    });

    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error("Usuário não autenticado.");

    console.log(`--- INICIO PROCESSAMENTO: ${chave_acesso} ---`);

    const scrapeResponse = await fetch(BROWSERLESS_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        code: puppeteerScript, 
        context: { url: "https://consultadfe.fazenda.rj.gov.br/consultaDFe/paginas/consultaChaveAcesso.faces", chave_acesso } 
      })
    });

    if (!scrapeResponse.ok) {
        console.error('Erro HTTP Browserless:', scrapeResponse.status);
        throw new Error("Falha na comunicação com o motor de busca.");
    }
    
    const scrapedRaw = await scrapeResponse.json();
    const dadosLimpos = cleanUpData(scrapedRaw);
    console.log(`Dados extraídos com sucesso. Itens: ${dadosLimpos.produtos.length}`);

    // Persistência Mercado
    const { data: mData, error: mErr } = await supabase.from('mercados').upsert({
      cnpj: dadosLimpos.mercado.cnpj, nome: dadosLimpos.mercado.nome, endereco: dadosLimpos.mercado.endereco
    }, { onConflict: 'cnpj' }).select('id').single();
    if (mErr) throw mErr;

    // Persistência Produtos (Deduplicados)
    const uniqueProducts = Array.from(new Map(dadosLimpos.produtos.map((p: any) => [`${p.codigo}_${mData.id}`, {
      codigo: p.codigo, nome: p.nome, valor_unitario: p.valor_unitario, unidade_medida: p.unidade, mercado_id: mData.id
    }])).values());
    
    const { data: pData, error: pErr } = await supabase.from('produtos').upsert(uniqueProducts, { onConflict: 'codigo, mercado_id' }).select('id, codigo');
    if (pErr) throw pErr;

    const mapaProdutos = new Map(pData.map((p: any) => [p.codigo, p.id]));
    const dataEmissaoISO = parseDate(dadosLimpos.data_emissao);

    // Inserção da Nota
    const { data: nfData, error: nfErr } = await supabase.from('notas_fiscais').insert({
      chave_acesso, data_de_emissao: dataEmissaoISO, valor_total: dadosLimpos.totais.valor_total,
      qtd_total_itens: dadosLimpos.totais.qtd_itens, mercado_id: mData.id, user_id: user.id
    }).select('id').single();
    if (nfErr) throw nfErr;

    // Inserção Itens
    const itens = dadosLimpos.produtos.map((p: any) => ({
      nota_fiscal_id: nfData.id, produto_id: mapaProdutos.get(p.codigo),
      quantidade: p.quantidade, valor_total_item: p.valor_total_item
    }));
    await supabase.from('itens_nota_fiscal').insert(itens);

    console.log('--- SUCESSO: Nota salva no banco ---');

    // Dispara batch-embed (Fire and forget)
    fetch(`${Deno.env.get("SUPABASE_URL")}/functions/v1/batch-embed`, {
      method: "POST", headers: { "Content-Type": "application/json", "Authorization": authHeader! }, body: JSON.stringify({})
    }).catch(() => {});

    return new Response(JSON.stringify({ message: "Sucesso!", id: nfData.id }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('--- ERRO FATAL ---');
    console.error(error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});
