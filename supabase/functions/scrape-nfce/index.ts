import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  persistInvoiceData,
  scrapeNfce,
} from "../_shared/nfce.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { chave_acesso } = await req.json();
    if (!chave_acesso) {
      throw new Error("Chave de acesso é obrigatória");
    }

    const authHeader = req.headers.get("Authorization");
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader! } } },
    );

    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      throw new Error("Usuário não autenticado.");
    }

    const invoice = await scrapeNfce(chave_acesso);
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const persistedInvoice = await persistInvoiceData(
      supabaseAdmin,
      user.id,
      invoice,
    );

    return new Response(
      JSON.stringify({ message: "Sucesso!", id: persistedInvoice.notaFiscalId }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error(error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
