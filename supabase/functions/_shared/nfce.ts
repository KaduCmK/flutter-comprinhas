export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};

const BROWSERLESS_API_KEY = Deno.env.get("BROWSERLESS_API_KEY");
const BROWSERLESS_URL = BROWSERLESS_API_KEY
  ? `https://production-sfo.browserless.io/function?token=${BROWSERLESS_API_KEY}`
  : null;

export type CleanedInvoiceProduct = {
  temp_id: string;
  codigo: string | null;
  nome: string;
  quantidade: number;
  unidade: string | null;
  valor_unitario: number;
  valor_total_item: number;
};

export type CleanedInvoiceData = {
  mercado: {
    nome: string;
    cnpj: string | null;
    endereco: string | null;
  };
  produtos: CleanedInvoiceProduct[];
  totais: {
    qtd_itens: number;
    valor_total: number;
  };
  data_emissao: string | null;
  data_emissao_iso: string | null;
  chave_acesso: string;
};

export type PersistedInvoiceData = {
  notaFiscalId: string;
  mercadoId: string;
  productsByTempId: Map<string, { produtoId: string | null }>;
  invoiceItemsByTempId: Map<
    string,
    { itemId: string; produtoId: string | null; productName: string }
  >;
};

export type CartItemForMatching = {
  cart_item_id: string;
  list_item_id: string;
  user_id: string | null;
  name: string;
  amount: number;
  unit_id: string | null;
  unit_label: string | null;
  list_id: string;
  list_name: string;
};

export class HttpError extends Error {
  status: number;

  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

export type InvoiceMatchCandidate = {
  invoice_item_temp_id: string;
  product_name: string;
  unit_label: string | null;
  quantity: number;
  unit_price: number;
  total_price: number;
  similarity: number;
};

export type CartItemMatchPreview = {
  cart_item_id: string;
  list_item_id: string;
  name: string;
  amount: number;
  unit_label: string | null;
  status: "matched" | "ambiguous" | "unmatched";
  selected_invoice_item_temp_id: string | null;
  selected_product_name: string | null;
  selected_similarity: number | null;
  recorded_unit_price: number | null;
  recorded_total_price: number | null;
  candidates: InvoiceMatchCandidate[];
};

export type InvoiceExtraPreviewItem = {
  invoice_item_temp_id: string;
  product_name: string;
  quantity: number;
  unit_label: string | null;
  unit_price: number;
  total_price: number;
};

const puppeteerScript = `
  export default async ({ page, context }) => {
    const { url, chave_acesso } = context;

    await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36');
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 20000 });

    const inputSelector = 'input[id$="chaveAcesso"], input[name$="chaveAcesso"], #chaveAcesso';
    await page.waitForSelector(inputSelector, { timeout: 10000 });
    await page.type(inputSelector, chave_acesso);

    const btnSelector = 'input[type="submit"], button[type="submit"], .btn-primary';
    await page.click(btnSelector);

    try {
      await page.waitForSelector('#tabResult', { timeout: 20000 });
    } catch (e) {
      const errorMsg = await page.evaluate(() => {
        const el = document.querySelector('.rf-msgs-sum') || document.querySelector('.textoErro') || document.querySelector('.alert-danger');
        return el ? el.textContent.trim() : null;
      });
      if (errorMsg) throw new Error(errorMsg);

      const screenshot = await page.screenshot({ encoding: 'base64' });
      console.error('SCREENSHOT EM FALHA:', screenshot);
      throw new Error('Timeout aguardando #tabResult. Verifique o log de screenshot.');
    }

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
        produtos: Array.from(document.querySelectorAll('#tabResult > tbody > tr')).map((row) => ({
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
          const label = strongs.find((s) => s.textContent.trim() === 'Emissão:');
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

function parseFloatSafe(value: string | null | undefined) {
  if (!value) return 0;
  const normalized = value
    .replace(/[R$\s]/g, "")
    .replace(/\.(?=\d{3}(\D|$))/g, "")
    .replace(",", ".");
  const parsed = Number.parseFloat(normalized);
  return Number.isFinite(parsed) ? parsed : 0;
}

function parseIntegerSafe(value: string | null | undefined) {
  if (!value) return 0;
  const digits = value.replace(/\D/g, "");
  const parsed = Number.parseInt(digits, 10);
  return Number.isFinite(parsed) ? parsed : 0;
}

export function parseDate(dateString: string | null) {
  if (!dateString) return null;
  const parts = dateString.match(
    /(\d{2})\/(\d{2})\/(\d{4})\s+(\d{2}):(\d{2}):(\d{2})/,
  );
  if (!parts) return null;
  return `${parts[3]}-${parts[2]}-${parts[1]}T${parts[4]}:${parts[5]}:${parts[6]}`;
}

export function cleanUpData(
  scraped: any,
  chaveAcesso: string,
): CleanedInvoiceData {
  const produtos = (scraped.produtos ?? []).map((p: any, index: number) => ({
    temp_id: `nf_item_${index}`,
    codigo: p.codigo
      ?.replace("(Código:", "")
      .replace(")", "")
      .trim() || null,
    nome: p.nome?.trim() || `Item ${index + 1}`,
    quantidade: parseFloatSafe(
      p.qtd?.replace("Qtde.:", "").trim() ?? "0",
    ),
    unidade: p.unidade?.replace("UN:", "").trim() || null,
    valor_unitario: parseFloatSafe(
      p.valor_unitario?.replace("Vl. Unit.:", "").trim() ?? "0",
    ),
    valor_total_item: parseFloatSafe(p.valor_total),
  }));

  return {
    mercado: {
      nome: scraped.mercado?.nome ?? "Mercado Desconhecido",
      cnpj: scraped.mercado?.cnpj?.replace(/\D/g, "") || null,
      endereco: scraped.mercado?.endereco?.replace(/\s+/g, " ").trim() || null,
    },
    produtos,
    totais: {
      qtd_itens: parseIntegerSafe(scraped.totais?.qtdItens),
      valor_total: parseFloatSafe(scraped.totais?.valorPagar),
    },
    data_emissao: scraped.data_emissao ?? null,
    data_emissao_iso: parseDate(scraped.data_emissao ?? null),
    chave_acesso: chaveAcesso,
  };
}

export async function scrapeNfce(
  chaveAcesso: string,
): Promise<CleanedInvoiceData> {
  if (!BROWSERLESS_URL) {
    throw new Error("BROWSERLESS_API_KEY não configurada.");
  }

  const scrapeResponse = await fetch(BROWSERLESS_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      code: puppeteerScript,
      context: {
        url:
          "https://consultadfe.fazenda.rj.gov.br/consultaDFe/paginas/consultaChaveAcesso.faces",
        chave_acesso: chaveAcesso,
      },
    }),
  });

  if (!scrapeResponse.ok) {
    throw new Error("Falha na comunicação com o motor de busca.");
  }

  const scrapedRaw = await scrapeResponse.json();
  return cleanUpData(scrapedRaw, chaveAcesso);
}

export async function getEmbedding(text: string, apiKey: string) {
  const modelName = "models/gemini-embedding-001";
  const url =
    `https://generativelanguage.googleapis.com/v1beta/${modelName}:embedContent?key=${apiKey}`;

  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model: modelName,
      content: { parts: [{ text }] },
      outputDimensionality: 768,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error("Erro na API Gemini:", errorText);
    throw new Error(`Gemini API Error (${response.status})`);
  }

  const data = await response.json();
  if (!data.embedding?.values) {
    throw new Error("Resposta de embedding inválida.");
  }

  return data.embedding.values as number[];
}

function cosineSimilarity(a: number[], b: number[]) {
  let dot = 0;
  let normA = 0;
  let normB = 0;

  for (let i = 0; i < a.length; i += 1) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }

  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}

type InternalMatch = InvoiceMatchCandidate & { is_auto_match?: boolean };

export async function previewInvoiceMatches(
  cartItems: CartItemForMatching[],
  invoice: CleanedInvoiceData,
) {
  const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
  if (!geminiApiKey) {
    throw new Error("GEMINI_API_KEY não configurada.");
  }

  const cartEmbeddings = await Promise.all(
    cartItems.map(async (item) => ({
      cart_item_id: item.cart_item_id,
      values: await getEmbedding(item.name.toUpperCase(), geminiApiKey),
    })),
  );
  const invoiceEmbeddings = await Promise.all(
    invoice.produtos.map(async (item) => ({
      invoice_item_temp_id: item.temp_id,
      values: await getEmbedding(item.nome.toUpperCase(), geminiApiKey),
    })),
  );

  const invoiceById = new Map(invoice.produtos.map((item) => [item.temp_id, item]));
  const invoiceEmbeddingById = new Map(
    invoiceEmbeddings.map((item) => [item.invoice_item_temp_id, item.values]),
  );

  const previews: CartItemMatchPreview[] = cartItems.map((cartItem) => {
    const cartVector = cartEmbeddings.find((item) =>
      item.cart_item_id === cartItem.cart_item_id
    )!.values;

    const candidates = invoice.produtos.map((invoiceItem) => {
      const similarity = cosineSimilarity(
        cartVector,
        invoiceEmbeddingById.get(invoiceItem.temp_id)!,
      );

      return {
        invoice_item_temp_id: invoiceItem.temp_id,
        product_name: invoiceItem.nome,
        unit_label: invoiceItem.unidade,
        quantity: invoiceItem.quantidade,
        unit_price: invoiceItem.valor_unitario,
        total_price: invoiceItem.valor_total_item,
        similarity,
      };
    }).sort((a, b) => b.similarity - a.similarity);

    const viableCandidates = candidates.filter((candidate) => candidate.similarity >= 0.65);
    const best = viableCandidates[0];
    const second = viableCandidates[1];

    let status: "matched" | "ambiguous" | "unmatched" = "unmatched";
    let selectedInvoiceItemTempId: string | null = null;

    if (best) {
      const isAmbiguous =
        best.similarity < 0.72 ||
        (second != null && best.similarity - second.similarity < 0.03);

      status = isAmbiguous ? "ambiguous" : "matched";
      selectedInvoiceItemTempId = status == "matched" ? best.invoice_item_temp_id : null;
    }

    return {
      cart_item_id: cartItem.cart_item_id,
      list_item_id: cartItem.list_item_id,
      name: cartItem.name,
      amount: cartItem.amount,
      unit_label: cartItem.unit_label,
      status,
      selected_invoice_item_temp_id: selectedInvoiceItemTempId,
      selected_product_name: best?.product_name,
      selected_similarity: best?.similarity ?? null,
      recorded_unit_price: best?.unit_price ?? null,
      recorded_total_price: best?.total_price ?? null,
      candidates: viableCandidates.slice(0, 5),
    };
  });

  const groupedByInvoice = new Map<string, CartItemMatchPreview[]>();
  for (const preview of previews.filter((item) =>
    item.selected_invoice_item_temp_id != null
  )) {
    const invoiceId = preview.selected_invoice_item_temp_id!;
    const existing = groupedByInvoice.get(invoiceId) ?? [];
    existing.push(preview);
    groupedByInvoice.set(invoiceId, existing);
  }

  for (const [, conflictPreviews] of groupedByInvoice.entries()) {
    if (conflictPreviews.length <= 1) continue;
    conflictPreviews.sort(
      (a, b) => (b.selected_similarity ?? 0) - (a.selected_similarity ?? 0),
    );
    for (let index = 1; index < conflictPreviews.length; index += 1) {
      const preview = conflictPreviews[index];
      preview.status = "ambiguous";
      preview.selected_invoice_item_temp_id = null;
    }
  }

  const usedInvoiceIds = previews
    .map((item) => item.selected_invoice_item_temp_id)
    .filter((id): id is string => id != null);

  const extraItems: InvoiceExtraPreviewItem[] = invoice.produtos
    .filter((item) => !usedInvoiceIds.includes(item.temp_id))
    .map((item) => ({
      invoice_item_temp_id: item.temp_id,
      product_name: item.nome,
      quantity: item.quantidade,
      unit_label: item.unidade,
      unit_price: item.valor_unitario,
      total_price: item.valor_total_item,
    }));

  return {
    cart_items: previews,
    extra_items: extraItems,
    summary: {
      matched_items_count: previews.filter((item) => item.status === "matched").length,
      ambiguous_items_count: previews.filter((item) => item.status === "ambiguous").length,
      unmatched_items_count: previews.filter((item) => item.status === "unmatched").length,
      invoice_extra_items_count: extraItems.length,
    },
  };
}

export async function loadAuthorizedCartItemsForInvoiceFlow({
  supabaseAdmin,
  userId,
  cartItemIds,
}: {
  supabaseAdmin: any;
  userId: string;
  cartItemIds: string[];
}): Promise<CartItemForMatching[]> {
  const uniqueCartItemIds = Array.from(new Set(cartItemIds));
  if (uniqueCartItemIds.length !== cartItemIds.length) {
    throw new HttpError(
      400,
      "A requisição contém itens duplicados do carrinho.",
    );
  }

  const { data: cartItems, error: cartError } = await supabaseAdmin
    .from("cart_items")
    .select(
      "id, user_id, list_items!inner(id, name, amount, unit_id, list_id, lists!inner(id, name, cart_mode), units(id, abbreviation))",
    )
    .in("id", uniqueCartItemIds);

  if (cartError) {
    throw new HttpError(
      500,
      `Erro ao carregar itens do carrinho: ${cartError.message}`,
    );
  }

  if (!cartItems?.length) {
    throw new HttpError(404, "Nenhum item do carrinho foi encontrado.");
  }

  if (cartItems.length !== uniqueCartItemIds.length) {
    throw new HttpError(
      403,
      "Há itens do carrinho inacessíveis para o usuário autenticado.",
    );
  }

  const listIds = new Set(
    cartItems.map((item: any) => item.list_items.list_id as string),
  );
  if (listIds.size !== 1) {
    throw new HttpError(
      400,
      "A compra com NF deve pertencer a uma única lista.",
    );
  }

  const listId = cartItems[0].list_items.list_id as string;
  const listMode = cartItems[0].list_items.lists?.cart_mode as string? ?? "shared";

  const { data: membership, error: membershipError } = await supabaseAdmin
    .from("list_members")
    .select("user_id")
    .eq("list_id", listId)
    .eq("user_id", userId)
    .maybeSingle();

  if (membershipError) {
    throw new HttpError(
      500,
      `Erro ao validar acesso à lista: ${membershipError.message}`,
    );
  }

  if (!membership) {
    throw new HttpError(
      403,
      "O usuário autenticado não tem acesso à lista informada.",
    );
  }

  if (listMode === "individual") {
    const hasForeignItems = cartItems.some((item: any) => item.user_id !== userId);
    if (hasForeignItems) {
      throw new HttpError(
        403,
        "No modo individual, só é permitido revisar ou confirmar itens do próprio usuário.",
      );
    }
  }

  return cartItems.map((cartItem: any) => ({
    cart_item_id: cartItem.id,
    list_item_id: cartItem.list_items.id,
    user_id: cartItem.user_id,
    name: cartItem.list_items.name,
    amount: Number(cartItem.list_items.amount ?? 0),
    unit_id: cartItem.list_items.unit_id ?? null,
    unit_label: cartItem.list_items.units?.abbreviation ?? null,
    list_id: cartItem.list_items.list_id,
    list_name: cartItem.list_items.lists.name,
  }));
}

export async function persistInvoiceData(
  supabaseClient: any,
  userId: string,
  invoice: CleanedInvoiceData,
  options?: {
    authorizationHeader?: string;
  },
): Promise<PersistedInvoiceData> {
  const { data: existingInvoice } = await supabaseClient
    .from("notas_fiscais")
    .select("id")
    .eq("chave_acesso", invoice.chave_acesso)
    .maybeSingle();

  if (existingInvoice) {
    throw new HttpError(
      409,
      "Esta nota fiscal já foi processada anteriormente.",
    );
  }

  const { data: mercado, error: mercadoError } = await supabaseClient
    .from("mercados")
    .upsert(
      {
        cnpj: invoice.mercado.cnpj,
        nome: invoice.mercado.nome,
        endereco: invoice.mercado.endereco,
      },
      { onConflict: "cnpj" },
    )
    .select("id")
    .single();

  if (mercadoError) throw mercadoError;

  const uniqueProducts = Array.from(
    new Map(
      invoice.produtos.map((product) => [
        `${product.codigo ?? product.nome}_${mercado.id}`,
        {
          temp_id: product.temp_id,
          codigo: product.codigo,
          nome: product.nome,
          valor_unitario: product.valor_unitario,
          unidade_medida: product.unidade,
          mercado_id: mercado.id,
        },
      ]),
    ).values(),
  );

  const { data: persistedProducts, error: productsError } = await supabaseClient
    .from("produtos")
    .upsert(
      uniqueProducts.map((product) => ({
        codigo: product.codigo,
        nome: product.nome,
        valor_unitario: product.valor_unitario,
        unidade_medida: product.unidade_medida,
        mercado_id: product.mercado_id,
      })),
      { onConflict: "codigo, mercado_id" },
    )
    .select("id, codigo, nome");

  if (productsError) throw productsError;

  const productByLookup = new Map<string, string>();
  for (const product of persistedProducts ?? []) {
    const lookupKey = `${product.codigo ?? product.nome}_${mercado.id}`;
    productByLookup.set(lookupKey, product.id);
  }

  const { data: notaFiscal, error: notaFiscalError } = await supabaseClient
    .from("notas_fiscais")
    .insert({
      chave_acesso: invoice.chave_acesso,
      data_de_emissao: invoice.data_emissao_iso,
      valor_total: invoice.totais.valor_total,
      qtd_total_itens: invoice.totais.qtd_itens,
      mercado_id: mercado.id,
      user_id: userId,
    })
    .select("id")
    .single();

  if (notaFiscalError) throw notaFiscalError;

  const productsByTempId = new Map<string, { produtoId: string | null }>();
  const invoiceRows = invoice.produtos.map((product) => {
    const lookupKey = `${product.codigo ?? product.nome}_${mercado.id}`;
    const produtoId = productByLookup.get(lookupKey) ?? null;
    productsByTempId.set(product.temp_id, { produtoId });
    return {
      temp_id: product.temp_id,
      nota_fiscal_id: notaFiscal.id,
      produto_id: produtoId,
      quantidade: product.quantidade,
      valor_total_item: product.valor_total_item,
    };
  });

  const { data: invoiceItems, error: invoiceItemsError } = await supabaseClient
    .from("itens_nota_fiscal")
    .insert(
      invoiceRows.map((row) => ({
        nota_fiscal_id: row.nota_fiscal_id,
        produto_id: row.produto_id,
        quantidade: row.quantidade,
        valor_total_item: row.valor_total_item,
      })),
    )
    .select("id, produto_id");

  if (invoiceItemsError) throw invoiceItemsError;

  const invoiceItemsByTempId = new Map<
    string,
    { itemId: string; produtoId: string | null; productName: string }
  >();

  invoiceRows.forEach((row, index) => {
    const sourceProduct = invoice.produtos[index];
    const persistedItem = invoiceItems[index];
    invoiceItemsByTempId.set(row.temp_id, {
      itemId: persistedItem.id,
      produtoId: persistedItem.produto_id,
      productName: sourceProduct.nome,
    });
  });

  const batchEmbedHeaders: Record<string, string> = {
    "Content-Type": "application/json",
    apikey: Deno.env.get("SUPABASE_ANON_KEY")!,
  };

  if (options?.authorizationHeader) {
    batchEmbedHeaders.Authorization = options.authorizationHeader;
  }

  fetch(`${Deno.env.get("SUPABASE_URL")}/functions/v1/batch-embed`, {
    method: "POST",
    headers: batchEmbedHeaders,
    body: JSON.stringify({}),
  }).catch(() => {});

  return {
    notaFiscalId: notaFiscal.id,
    mercadoId: mercado.id,
    productsByTempId,
    invoiceItemsByTempId,
  };
}
