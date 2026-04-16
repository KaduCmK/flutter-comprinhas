import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  HttpError,
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
      throw new HttpError(400, "Chave de acesso é obrigatória");
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
      throw new HttpError(401, "Usuário não autenticado.");
    }

    const invoice = await scrapeNfce(chave_acesso);
    const persistedInvoice = await persistInvoiceData(
      supabase,
      user.id,
      invoice,
      { authorizationHeader: authHeader ?? undefined },
    );

    return new Response(
      JSON.stringify({ message: "Sucesso!", id: persistedInvoice.notaFiscalId }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error(error);
    const status = error instanceof HttpError ? error.status : 500;
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
