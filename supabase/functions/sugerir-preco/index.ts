import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2.44.4";

async function getEmbedding(text: string, apiKey: string): Promise<number[]> {
  const modelName = "models/gemini-embedding-001";
  const url = `https://generativelanguage.googleapis.com/v1beta/${modelName}:embedContent?key=${apiKey}`;
  
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
    console.error(`Erro na API Gemini (${modelName}):`, errorText);
    throw new Error(`Gemini API Error (${response.status})`);
  }

  const data = await response.json();
  if (!data.embedding || !data.embedding.values) {
    throw new Error("Resposta não contém o array de valores.");
  }
  return data.embedding.values;
}

serve(async (req) => {
  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { record } = await req.json();
    if (!record || !record.name || !record.id) {
      console.warn("Payload inválido recebido pelo gatilho.");
      return new Response(JSON.stringify({ message: "Payload inválido." }), { status: 400 });
    }

    const itemName = record.name.toUpperCase();
    const itemId = record.id;

    console.log(`Processando item: "${itemName}" (ID: ${itemId})`);

    let queryEmbedding;
    if (record.embedding && record.embedding.length > 0) {
      console.log(`Embedding já existe para o item "${itemName}". Usando o existente.`);
      queryEmbedding = record.embedding;
    } else {
      console.log(`Gerando novo embedding para o item "${itemName}".`);
      const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
      if (!geminiApiKey) throw new Error("GEMINI_API_KEY não configurado.");
      
      queryEmbedding = await getEmbedding(itemName, geminiApiKey);
      
      // Salva o novo embedding no banco
      await supabaseClient.from("list_items").update({
        embedding: queryEmbedding
      }).eq("id", itemId);
    }

    // Busca produtos similares - A RPC já retorna ordenado por similaridade DESC
    const { data: matchedProducts, error: rpcError } = await supabaseClient.rpc("match_product_by_embedding", {
      query_embedding: queryEmbedding,
      match_threshold: 0.5,
      match_count: 5
    });

    if (rpcError) throw rpcError;

    if (!matchedProducts || matchedProducts.length === 0) {
      console.log(`Nenhum produto encontrado com similaridade aceitável para "${itemName}".`);
      return new Response(JSON.stringify({ message: "Nenhum produto compatível encontrado." }), { status: 200 });
    }

    // Atualiza matches
    await supabaseClient.from("list_item_product_matches").delete().eq("list_item_id", itemId);
    
    const newMatches = matchedProducts.map((product: any) => ({
      list_item_id: itemId,
      produto_id: product.id,
      similarity_score: product.similarity
    }));

    await supabaseClient.from("list_item_product_matches").insert(newMatches);

    // CORREÇÃO: Encontra o produto MAIS SIMILAR que tenha preço (o primeiro da lista com preço)
    // matchedProducts já vem ordenado por similaridade decrescente da RPC
    const bestMatch = matchedProducts.find((p: any) => p.valor_unitario !== null);
    
    if (bestMatch) {
      // Busca a unidade de medida do produto pareado
      const { data: productData } = await supabaseClient
        .from("produtos")
        .select("unidade_medida")
        .eq("id", bestMatch.id)
        .single();

      await supabaseClient.from("list_items").update({
        preco_sugerido: bestMatch.valor_unitario,
        unidade_preco_sugerido: productData?.unidade_medida || null
      }).eq("id", itemId);

      console.log(`Preço sugerido de ${bestMatch.valor_unitario} (Unidade: ${productData?.unidade_medida}) para "${itemName}" (baseado no match mais similar: "${bestMatch.nome}" com ${(bestMatch.similarity * 100).toFixed(1)}%).`);
    } else {
      console.log(`Produtos similares a "${itemName}" encontrados, mas nenhum com preço.`);
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" }
    });

  } catch (error) {
    console.error("Erro na função sugerir-preco:", error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500
    });
  }
});
