import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  previewInvoiceMatches,
  scrapeNfce,
  type CartItemForMatching,
} from "../_shared/nfce.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { cart_items_ids, chave_acesso } = await req.json();
    if (!Array.isArray(cart_items_ids) || cart_items_ids.length === 0) {
      throw new Error("Nenhum item do carrinho para revisar.");
    }
    if (!chave_acesso) {
      throw new Error("Chave de acesso é obrigatória.");
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

    const { data: cartItems, error: cartError } = await supabaseAdmin
      .from("cart_items")
      .select(
        "id, user_id, list_items!inner(id, name, amount, unit_id, list_id, lists!inner(id, name), units(id, abbreviation))",
      )
      .in("id", cart_items_ids);

    if (cartError || !cartItems?.length) {
      throw new Error(`Erro ao carregar itens do carrinho: ${cartError?.message ?? ""}`);
    }

    const listIds = new Set(
      cartItems.map((item: any) => item.list_items.list_id as string),
    );
    if (listIds.size !== 1) {
      throw new Error("A compra com NF deve pertencer a uma única lista.");
    }

    const reviewItems: CartItemForMatching[] = cartItems.map((cartItem: any) => ({
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
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
