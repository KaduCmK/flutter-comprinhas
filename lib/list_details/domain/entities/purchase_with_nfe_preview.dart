import 'package:equatable/equatable.dart';
import 'package:flutter_comprinhas/shared/entities/mercado.dart';

class PurchaseWithNfePreview extends Equatable {
  final InvoicePreview invoice;
  final List<CartReviewItem> cartItems;
  final List<InvoiceExtraItem> extraItems;
  final ReviewSummary summary;

  const PurchaseWithNfePreview({
    required this.invoice,
    required this.cartItems,
    required this.extraItems,
    required this.summary,
  });

  factory PurchaseWithNfePreview.fromMap(Map<String, dynamic> map) {
    final invoiceMap = map['invoice'] as Map<String, dynamic>;
    final reviewMap = map['review'] as Map<String, dynamic>;

    return PurchaseWithNfePreview(
      invoice: InvoicePreview.fromMap(invoiceMap),
      cartItems:
          (reviewMap['cart_items'] as List<dynamic>)
              .map(
                (item) => CartReviewItem.fromMap(item as Map<String, dynamic>),
              )
              .toList(),
      extraItems:
          (reviewMap['extra_items'] as List<dynamic>)
              .map(
                (item) =>
                    InvoiceExtraItem.fromMap(item as Map<String, dynamic>),
              )
              .toList(),
      summary: ReviewSummary.fromMap(
        reviewMap['summary'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  List<Object?> get props => [invoice, cartItems, extraItems, summary];
}

class InvoicePreview extends Equatable {
  final String chaveAcesso;
  final DateTime? dataEmissao;
  final Mercado mercado;
  final double valorTotal;
  final int quantidadeItens;
  final List<InvoicePreviewItem> items;

  const InvoicePreview({
    required this.chaveAcesso,
    required this.dataEmissao,
    required this.mercado,
    required this.valorTotal,
    required this.quantidadeItens,
    required this.items,
  });

  factory InvoicePreview.fromMap(Map<String, dynamic> map) {
    final totais = map['totais'] as Map<String, dynamic>;

    return InvoicePreview(
      chaveAcesso: map['chave_acesso'] as String,
      dataEmissao:
          map['data_emissao_iso'] != null
              ? DateTime.parse(map['data_emissao_iso'] as String)
              : null,
      mercado: Mercado.fromMap({
        'id': 'preview',
        ...(map['mercado'] as Map<String, dynamic>),
      }),
      valorTotal: (totais['valor_total'] as num).toDouble(),
      quantidadeItens: (totais['qtd_itens'] as num).toInt(),
      items:
          (map['produtos'] as List<dynamic>)
              .map(
                (item) =>
                    InvoicePreviewItem.fromMap(item as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  @override
  List<Object?> get props => [
    chaveAcesso,
    dataEmissao,
    mercado,
    valorTotal,
    quantidadeItens,
    items,
  ];
}

class InvoicePreviewItem extends Equatable {
  final String tempId;
  final String nome;
  final double quantidade;
  final String? unidade;
  final double valorUnitario;
  final double valorTotal;

  const InvoicePreviewItem({
    required this.tempId,
    required this.nome,
    required this.quantidade,
    required this.unidade,
    required this.valorUnitario,
    required this.valorTotal,
  });

  factory InvoicePreviewItem.fromMap(Map<String, dynamic> map) {
    return InvoicePreviewItem(
      tempId: map['temp_id'] as String,
      nome: map['nome'] as String,
      quantidade: (map['quantidade'] as num).toDouble(),
      unidade: map['unidade'] as String?,
      valorUnitario: (map['valor_unitario'] as num).toDouble(),
      valorTotal: (map['valor_total_item'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    tempId,
    nome,
    quantidade,
    unidade,
    valorUnitario,
    valorTotal,
  ];
}

enum CartReviewStatus { matched, ambiguous, unmatched }

class CartReviewItem extends Equatable {
  final String cartItemId;
  final String listItemId;
  final String name;
  final double amount;
  final String? unitLabel;
  final CartReviewStatus status;
  final String? selectedInvoiceItemTempId;
  final String? selectedProductName;
  final double? selectedSimilarity;
  final double? recordedUnitPrice;
  final double? recordedTotalPrice;
  final List<InvoiceMatchCandidate> candidates;

  const CartReviewItem({
    required this.cartItemId,
    required this.listItemId,
    required this.name,
    required this.amount,
    required this.unitLabel,
    required this.status,
    required this.selectedInvoiceItemTempId,
    required this.selectedProductName,
    required this.selectedSimilarity,
    required this.recordedUnitPrice,
    required this.recordedTotalPrice,
    required this.candidates,
  });

  bool get needsReview => status == CartReviewStatus.ambiguous;

  factory CartReviewItem.fromMap(Map<String, dynamic> map) {
    return CartReviewItem(
      cartItemId: map['cart_item_id'] as String,
      listItemId: map['list_item_id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      unitLabel: map['unit_label'] as String?,
      status: CartReviewStatus.values.firstWhere(
        (value) => value.name == map['status'],
      ),
      selectedInvoiceItemTempId:
          map['selected_invoice_item_temp_id'] as String?,
      selectedProductName: map['selected_product_name'] as String?,
      selectedSimilarity: (map['selected_similarity'] as num?)?.toDouble(),
      recordedUnitPrice: (map['recorded_unit_price'] as num?)?.toDouble(),
      recordedTotalPrice: (map['recorded_total_price'] as num?)?.toDouble(),
      candidates:
          (map['candidates'] as List<dynamic>)
              .map(
                (item) =>
                    InvoiceMatchCandidate.fromMap(item as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  @override
  List<Object?> get props => [
    cartItemId,
    listItemId,
    name,
    amount,
    unitLabel,
    status,
    selectedInvoiceItemTempId,
    selectedProductName,
    selectedSimilarity,
    recordedUnitPrice,
    recordedTotalPrice,
    candidates,
  ];
}

class InvoiceMatchCandidate extends Equatable {
  final String invoiceItemTempId;
  final String productName;
  final String? unitLabel;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final double similarity;

  const InvoiceMatchCandidate({
    required this.invoiceItemTempId,
    required this.productName,
    required this.unitLabel,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.similarity,
  });

  factory InvoiceMatchCandidate.fromMap(Map<String, dynamic> map) {
    return InvoiceMatchCandidate(
      invoiceItemTempId: map['invoice_item_temp_id'] as String,
      productName: map['product_name'] as String,
      unitLabel: map['unit_label'] as String?,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
      similarity: (map['similarity'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    invoiceItemTempId,
    productName,
    unitLabel,
    quantity,
    unitPrice,
    totalPrice,
    similarity,
  ];
}

class InvoiceExtraItem extends Equatable {
  final String invoiceItemTempId;
  final String productName;
  final double quantity;
  final String? unitLabel;
  final double unitPrice;
  final double totalPrice;

  const InvoiceExtraItem({
    required this.invoiceItemTempId,
    required this.productName,
    required this.quantity,
    required this.unitLabel,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory InvoiceExtraItem.fromMap(Map<String, dynamic> map) {
    return InvoiceExtraItem(
      invoiceItemTempId: map['invoice_item_temp_id'] as String,
      productName: map['product_name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitLabel: map['unit_label'] as String?,
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    invoiceItemTempId,
    productName,
    quantity,
    unitLabel,
    unitPrice,
    totalPrice,
  ];
}

class ReviewSummary extends Equatable {
  final int matchedItemsCount;
  final int ambiguousItemsCount;
  final int unmatchedItemsCount;
  final int invoiceExtraItemsCount;

  const ReviewSummary({
    required this.matchedItemsCount,
    required this.ambiguousItemsCount,
    required this.unmatchedItemsCount,
    required this.invoiceExtraItemsCount,
  });

  factory ReviewSummary.fromMap(Map<String, dynamic> map) {
    return ReviewSummary(
      matchedItemsCount: (map['matched_items_count'] as num).toInt(),
      ambiguousItemsCount: (map['ambiguous_items_count'] as num).toInt(),
      unmatchedItemsCount: (map['unmatched_items_count'] as num).toInt(),
      invoiceExtraItemsCount: (map['invoice_extra_items_count'] as num).toInt(),
    );
  }

  @override
  List<Object?> get props => [
    matchedItemsCount,
    ambiguousItemsCount,
    unmatchedItemsCount,
    invoiceExtraItemsCount,
  ];
}
