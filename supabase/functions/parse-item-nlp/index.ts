import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { query, units } = await req.json();

    if (!query) {
      return new Response(JSON.stringify({ error: "Query is required" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      });
    }

    const warmindUrl = Deno.env.get("WARMIND_API_URL");
    const warmindKey = Deno.env.get("WARMIND_API_KEY");

    if (!warmindUrl || !warmindKey) {
      return new Response(JSON.stringify({ error: "WARMIND_API_URL or WARMIND_API_KEY is not set" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      });
    }

    const systemInstruction = `
You are an intelligent shopping list assistant. Your task is to parse user input in natural language and extract the item name, amount, and the most appropriate unit of measurement from the provided list of units.

Available units:
${JSON.stringify(units, null, 2)}

Rules:
1. Extract the quantity (amount) as a number. If not specified, default to 1.
2. Extract the item name clearly and concisely (e.g., "Carne moída", "Macarrão espaguete"). If the user specifies a package size like "700g" and the unit chosen is "pacotes" or "unidades", include the size in the name (e.g., "Macarrão pacote 700g").
3. Match the unit requested by the user to the closest available unit from the provided list, and return its "id". If no unit matches perfectly, or if no unit is specified, use the ID of the unit representing "unidades" or "un".
4. You MUST return ONLY the JSON object itself, exactly matching the schema. DO NOT nest it inside any other key or add any introductory text.

Format example (STRICT):
{
  "name": "Item name",
  "amount": 1,
  "unit_id": "uuid-here"
}
`;

    console.log(`Processing NLP with Warmind (Oracle) for query: "${query}"`);
    
    const response = await fetch(`${warmindUrl}/api/inference/structured`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Warmind-Key": warmindKey,
      },
      body: JSON.stringify({
        model: "llama3.2:1b", // Modelo local rodando no Ollama da Oracle
        systemPrompt: systemInstruction,
        userPrompt: query,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("Warmind API error:", errorText);
      throw new Error(`Warmind API failed with status ${response.status}: ${errorText}`);
    }

    const parsedData = await response.json();

    return new Response(JSON.stringify(parsedData), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error) {
    console.error("Function error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
