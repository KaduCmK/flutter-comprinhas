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

    const systemInstruction = `
Your task: Extract structured shopping list data from a natural language string.

Available Units (Use ONLY these IDs):
${units.map((u: any) => `- ${u.id}: ${u.name} (${u.abbreviation})`).join("\n")}

CRITICAL BUSINESS LOGIC:
There are two types of products in a supermarket:
A. "Weighed Items" (Items bought by weight/volume directly at the counter, like meat, loose cheese, vegetables).
B. "Packaged Items" (Items bought in closed containers, boxes, bottles, or bags, like a bottle of soda or a bag of pasta).

Processing Rules:
1. "unit_id": 
   - If it is a "Packaged Item" (e.g., "pacotes de macarrão", "caixa de leite", "pepsi 2 litros"), the unit of purchase is ALWAYS "Unidade" (find the ID for 'unidades' or 'un'). 
   - If it is a "Weighed Item" (e.g., "acém moído", "queijo prato", "tomate"), use the specific weight/volume unit mentioned (kg, g, L).

2. "amount": 
   - Extract the quantity OF THE PURCHASE UNIT. 
   - For "3 pacotes de macarrão 700g", the amount is 3 (you are buying 3 units).
   - For "pepsi zero 2 litros" (if no explicit quantity is given), the amount is 1 (you are buying 1 unit of the 2L bottle).
   - For "200g queijo prato", the amount is 200 (weighed item).
   - Default is 1 if not specified.

3. "name": 
   - Extract the core item name. 
   - CRITICAL: Remove the purchase quantity (e.g., "3 pacotes", "1kg"), BUT KEEP all descriptive information, including package sizes, weights, or volumes that describe the specific product.
   - Example: "3 pacotes de macarrão 700g" -> "Macarrão 700g" (Kept the 700g descriptor).
   - Example: "pepsi zero 2 litros" -> "Pepsi Zero 2 litros" (Kept the 2L descriptor).
   - Example: "3kg acém moído" -> "Acém moído" (Weighed item, the 3kg is the purchase amount, so remove it from the name).

Output Format:
Return ONLY the JSON object. No other text. No nesting.

Example Rule:
Input: "5 caixas de leite integral 1L"
Output: {"name": "Leite integral 1L", "amount": 5, "unit_id": "ID_OF_UNIDADES"}

Input: "500g presunto fatiado"
Output: {"name": "Presunto fatiado", "amount": 500, "unit_id": "ID_OF_GRAMS"}

User Query: "${query}"
Output:
`;

    // Configuração de Fallback / Híbrida
    const llmProvider = Deno.env.get("LLM_PROVIDER") || "gemini"; // Pode ser "gemini" ou "warmind"
    let parsedData = null;

    if (llmProvider === "warmind") {
      // ----------------------------------------------------
      // FLUXO WARMIND (OLLAMA LOCAL NA ORACLE)
      // ----------------------------------------------------
      const warmindUrl = Deno.env.get("WARMIND_API_URL");
      const warmindKey = Deno.env.get("WARMIND_API_KEY");

      if (!warmindUrl || !warmindKey) {
        throw new Error("WARMIND_API_URL or WARMIND_API_KEY is not set");
      }

      console.log(`Routing to Warmind API for query: "${query}"`);
      
      const response = await fetch(`${warmindUrl}/api/inference/structured`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Warmind-Key": warmindKey,
        },
        body: JSON.stringify({
          model: "gemma2:2b", // Modelo local recomendado
          systemPrompt: systemInstruction,
          userPrompt: query,
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error("Warmind API error:", errorText);
        throw new Error(`Warmind API failed with status ${response.status}: ${errorText}`);
      }

      parsedData = await response.json();

    } else {
      // ----------------------------------------------------
      // FLUXO GEMINI (DEFAULT / CLOUD)
      // ----------------------------------------------------
      const apiKey = Deno.env.get("GEMINI_API_KEY");
      if (!apiKey) {
        return new Response(JSON.stringify({ error: "GEMINI_API_KEY is not set" }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 500,
        });
      }

      console.log(`Routing to Gemini API for query: "${query}"`);

      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            system_instruction: {
              parts: [{ text: systemInstruction }],
            },
            contents: [
              {
                role: "user",
                parts: [{ text: query }],
              },
            ],
            generationConfig: {
              response_mime_type: "application/json",
              response_schema: {
                type: "OBJECT",
                properties: {
                  name: { type: "STRING" },
                  amount: { type: "NUMBER" },
                  unit_id: { type: "STRING" },
                },
                required: ["name", "amount", "unit_id"],
              },
            },
          }),
        }
      );

      if (!response.ok) {
        const errorText = await response.text();
        console.error("Gemini API error:", errorText);
        throw new Error(`Gemini API failed with status ${response.status}: ${errorText}`);
      }

      const data = await response.json();
      const resultText = data.candidates?.[0]?.content?.parts?.[0]?.text;
      
      if (!resultText) {
        throw new Error("No text returned from Gemini");
      }

      parsedData = JSON.parse(resultText);
    }

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
