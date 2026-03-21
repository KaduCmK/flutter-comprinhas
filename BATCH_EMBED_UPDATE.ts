// supabase/functions/batch-embed/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Tenta o modelo novo
async function getSingleEmbedding(text: string, apiKey: string): Promise<number[]> {
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
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Busca até 20 produtos
    const { data: products, error: selectError } = await supabaseClient
      .from("produtos")
      .select("id, nome")
      .is("embedding", null)
      .limit(20);

    if (selectError) throw selectError;
    if (!products || products.length === 0) {
      return new Response(JSON.stringify({ message: "Nenhum produto sem embedding." }), { status: 200 });
    }

    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiApiKey) throw new Error("GEMINI_API_KEY ausente.");

    console.log(`Iniciando geração para ${products.length} produtos...`);

    const results = await Promise.allSettled(
      products.map(p => getSingleEmbedding(p.nome, geminiApiKey))
    );

    const updatePromises = [];
    let successCount = 0;

    for (let i = 0; i < results.length; i++) {
      const res = results[i];
      if (res.status === 'fulfilled') {
        successCount++;
        updatePromises.push(
          supabaseClient
            .from("produtos")
            .update({ embedding: res.value })
            .eq('id', products[i].id)
        );
      }
    }

    await Promise.all(updatePromises);

    return new Response(JSON.stringify({ 
      success: true,
      processed: successCount,
      failed: products.length - successCount
    }), { 
      headers: { "Content-Type": "application/json", 'Access-Control-Allow-Origin': '*' } 
    });

  } catch (error) {
    console.error("ERRO GERAL:", error);
    return new Response(JSON.stringify({ error: error.message }), { 
      status: 500,
      headers: { "Content-Type": "application/json", 'Access-Control-Allow-Origin': '*' } 
    });
  }
});
