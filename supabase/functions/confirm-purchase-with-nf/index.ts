import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  HttpError,
  loadAuthorizedCartItemsForInvoiceFlow,
  persistInvoiceData,
  previewInvoiceMatches,
  scrapeNfce,
  type CartItemForMatching,
} from "../_shared/nfce.ts";

async function rollbackPurchaseWithInvoice({
  supabaseAdmin,
  historyId,
  notaFiscalId,
}: {
  supabaseAdmin: any;
  historyId: string | null;
  notaFiscalId: string | null;
}) {
  if (historyId) {
    const { error: historyItemsRollbackError } = await supabaseAdmin
      .from("purchase_history_items")
      .delete()
      .eq("purchase_history_id", historyId);
    if (historyItemsRollbackError) {
      console.error(
        "Erro ao remover purchase_history_items no rollback:",
        historyItemsRollbackError.message,
      );
    }

    const { error: historyRollbackError } = await supabaseAdmin
      .from("purchase_history")
      .delete()
      .eq("id", historyId);
    if (historyRollbackError) {
      console.error(
        "Erro ao remover purchase_history no rollback:",
        historyRollbackError.message,
      );
    }
  }

  if (notaFiscalId) {
    const { error: invoiceItemsRollbackError } = await supabaseAdmin
      .from("itens_nota_fiscal")
      .delete()
      .eq("nota_fiscal_id", notaFiscalId);
    if (invoiceItemsRollbackError) {
      console.error(
        "Erro ao remover itens_nota_fiscal no rollback:",
        invoiceItemsRollbackError.message,
      );
    }

    const { error: invoiceRollbackError } = await supabaseAdmin
      .from("notas_fiscais")
      .delete()
      .eq("id", notaFiscalId);
    if (invoiceRollbackError) {
      console.error(
        "Erro ao remover notas_fiscais no rollback:",
        invoiceRollbackError.message,
      );
    }
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  let createdHistoryId: string | null = null;
  let createdNotaFiscalId: string | null = null;

  try {
    const { cart_items_ids, chave_acesso, manual_matches } = await req.json();
    if (!Array.isArray(cart_items_ids) || cart_items_ids.length === 0) {
      throw new HttpError(400, "Nenhum item do carrinho para confirmar.");
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

    const reviewItems = await loadAuthorizedCartItemsForInvoiceFlow({
      supabaseAdmin,
      userId: user.id,
      cartItemIds: cart_items_ids,
    });

    const invoice = await scrapeNfce(chave_acesso);
    const preview = await previewInvoiceMatches(reviewItems, invoice);
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

    if (matchedCartEntries.length === 0) {
      throw new Error(
        "Nenhum item da cesta foi conciliado com a nota fiscal. Revise os matches antes de confirmar.",
      );
    }

    const persistedInvoice = await persistInvoiceData(
      supabaseAdmin,
      user.id,
      invoice,
      { authorizationHeader: authHeader ?? undefined },
    );
    createdNotaFiscalId = persistedInvoice.notaFiscalId;

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
    createdHistoryId = history.id;

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

    const [cartDeleteResult, listDeleteResult] = await Promise.all([
      supabaseAdmin.from("cart_items").delete().in("id", confirmedCartItemIds).select("id"),
      supabaseAdmin.from("list_items").delete().in("id", confirmedListItemIds).select("id"),
    ]);

    if (cartDeleteResult.error) {
      throw new Error(`Erro ao limpar carrinho: ${cartDeleteResult.error.message}`);
    }
    if (listDeleteResult.error) {
      throw new Error(`Erro ao limpar itens da lista: ${listDeleteResult.error.message}`);
    }

    const deletedCartIds = new Set(
      (cartDeleteResult.data ?? []).map((item: { id: string }) => item.id),
    );
    const deletedListIds = new Set(
      (listDeleteResult.data ?? []).map((item: { id: string }) => item.id),
    );

    if (deletedCartIds.size !== confirmedCartItemIds.length) {
      throw new Error(
        `Limpeza inconsistente do carrinho. Esperado remover ${confirmedCartItemIds.length} item(ns), mas removeu ${deletedCartIds.size}.`,
      );
    }

    if (deletedListIds.size !== confirmedListItemIds.length) {
      throw new Error(
        `Limpeza inconsistente da lista. Esperado remover ${confirmedListItemIds.length} item(ns), mas removeu ${deletedListIds.size}.`,
      );
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
    await rollbackPurchaseWithInvoice({
      supabaseAdmin,
      historyId: createdHistoryId,
      notaFiscalId: createdNotaFiscalId,
    });

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
