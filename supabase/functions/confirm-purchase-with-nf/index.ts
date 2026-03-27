import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  persistInvoiceData,
  previewInvoiceMatches,
  scrapeNfce,
  type CartItemForMatching,
} from "../_shared/nfce.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { cart_items_ids, chave_acesso, manual_matches } = await req.json();
    if (!Array.isArray(cart_items_ids) || cart_items_ids.length === 0) {
      throw new Error("Nenhum item do carrinho para confirmar.");
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
    const preview = await previewInvoiceMatches(reviewItems, invoice);
    const persistedInvoice = await persistInvoiceData(supabaseAdmin, user.id, invoice);

    const manualMatchMap = new Map<string, string | null>(
      Object.entries((manual_matches ?? {}) as Record<string, string | null>),
    );

    const usedInvoiceIds = new Set<string>();
    const matchedCartEntries: {
      cartItem: CartItemForMatching;
      invoiceTempId: string;
      matchingStatus: "matched" | "manual";
      similarity: number | null;
    }[] = [];

    for (const cartPreview of preview.cart_items) {
      let selectedInvoiceTempId = cartPreview.selected_invoice_item_temp_id;
      let matchingStatus: "matched" | "manual" = "matched";

      if (cartPreview.status === "ambiguous") {
        selectedInvoiceTempId = manualMatchMap.get(cartPreview.cart_item_id) ?? null;
        matchingStatus = "manual";
      }

      if (!selectedInvoiceTempId || usedInvoiceIds.has(selectedInvoiceTempId)) {
        continue;
      }

      usedInvoiceIds.add(selectedInvoiceTempId);
      const cartItem = reviewItems.find((item) =>
        item.cart_item_id === cartPreview.cart_item_id
      )!;

      matchedCartEntries.push({
        cartItem,
        invoiceTempId: selectedInvoiceTempId,
        matchingStatus,
        similarity: cartPreview.candidates
          .find((candidate) => candidate.invoice_item_temp_id === selectedInvoiceTempId)
          ?.similarity ?? cartPreview.selected_similarity,
      });
    }

    const { data: history, error: historyError } = await supabaseAdmin
      .from("purchase_history")
      .insert({
        user_id: user.id,
        nota_fiscal_id: persistedInvoice.notaFiscalId,
      })
      .select("id")
      .single();

    if (historyError || !history) {
      throw new Error(`Erro ao criar histórico da compra: ${historyError?.message ?? ""}`);
    }

    const historyItemsToInsert = matchedCartEntries.map((entry) => {
      const invoiceItem = invoice.produtos.find((item) => item.temp_id === entry.invoiceTempId)!;
      const persistedInvoiceItem = persistedInvoice.invoiceItemsByTempId.get(entry.invoiceTempId)!;

      return {
        purchase_history_id: history.id,
        name: entry.cartItem.name,
        amount: entry.cartItem.amount,
        unit_id: entry.cartItem.unit_id,
        raw_unit_label: entry.cartItem.unit_label,
        list_id: entry.cartItem.list_id,
        list_name: entry.cartItem.list_name,
        user_id: entry.cartItem.user_id,
        origin: "cart",
        nota_fiscal_item_id: persistedInvoiceItem.itemId,
        produto_id: persistedInvoiceItem.produtoId,
        recorded_unit_price: invoiceItem.valor_unitario,
        recorded_total_price: invoiceItem.valor_total_item,
        matching_status: entry.matchingStatus,
      };
    });

    const invoiceExtraItems = invoice.produtos.filter((item) => !usedInvoiceIds.has(item.temp_id));
    historyItemsToInsert.push(
      ...invoiceExtraItems.map((item) => {
        const persistedInvoiceItem = persistedInvoice.invoiceItemsByTempId.get(item.temp_id)!;
        const firstCartItem = reviewItems[0];

        return {
          purchase_history_id: history.id,
          name: item.nome,
          amount: item.quantidade,
          unit_id: null,
          raw_unit_label: item.unidade,
          list_id: firstCartItem.list_id,
          list_name: firstCartItem.list_name,
          user_id: user.id,
          origin: "invoice_extra",
          nota_fiscal_item_id: persistedInvoiceItem.itemId,
          produto_id: persistedInvoiceItem.produtoId,
          recorded_unit_price: item.valor_unitario,
          recorded_total_price: item.valor_total_item,
          matching_status: "invoice_extra",
        };
      }),
    );

    const { error: historyItemsError } = await supabaseAdmin
      .from("purchase_history_items")
      .insert(historyItemsToInsert);

    if (historyItemsError) {
      throw new Error(`Erro ao salvar itens do histórico: ${historyItemsError.message}`);
    }

    const confirmedCartItemIds = matchedCartEntries.map((entry) => entry.cartItem.cart_item_id);
    const confirmedListItemIds = matchedCartEntries.map((entry) => entry.cartItem.list_item_id);

    if (confirmedCartItemIds.isNotEmpty) {
      const [cartDeleteResult, listDeleteResult] = await Promise.all([
        supabaseAdmin.from("cart_items").delete().in("id", confirmedCartItemIds),
        supabaseAdmin.from("list_items").delete().in("id", confirmedListItemIds),
      ]);

      if (cartDeleteResult.error) {
        throw new Error(`Erro ao limpar carrinho: ${cartDeleteResult.error.message}`);
      }
      if (listDeleteResult.error) {
        throw new Error(`Erro ao limpar itens da lista: ${listDeleteResult.error.message}`);
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        purchase_history_id: history.id,
        nota_fiscal_id: persistedInvoice.notaFiscalId,
        matched_items_count: matchedCartEntries.length,
        invoice_extra_items_count: invoiceExtraItems.length,
        unmatched_cart_items_count:
          reviewItems.length - matchedCartEntries.length,
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
