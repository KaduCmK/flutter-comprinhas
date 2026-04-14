import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  HttpError,
  loadAuthorizedCartItemsForInvoiceFlow,
  previewInvoiceMatches,
  scrapeNfce,
} from "../_shared/nfce.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { cart_items_ids, chave_acesso } = await req.json();
    if (!Array.isArray(cart_items_ids) || cart_items_ids.length === 0) {
      throw new HttpError(400, "Nenhum item do carrinho para revisar.");
    }
    if (!chave_acesso) {
      throw new HttpError(400, "Chave de acesso é obrigatória.");
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
      return new Response(JSON.stringify({ error: "Usuário não autenticado." }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const reviewItems = await loadAuthorizedCartItemsForInvoiceFlow({
      supabaseAdmin,
      userId: user.id,
      cartItemIds: cart_items_ids,
    });

    const invoice = await scrapeNfce(chave_acesso);
    const matchPreview = await previewInvoiceMatches(reviewItems, invoice);

    return new Response(
      JSON.stringify({
        invoice: invoice,
        review: matchPreview,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
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
