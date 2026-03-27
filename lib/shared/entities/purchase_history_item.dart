import 'package:equatable/equatable.dart';
import 'package:flutter_comprinhas/shared/entities/unit.dart';

enum PurchaseHistoryItemOrigin { cart, invoiceExtra }

class PurchaseHistoryItem extends Equatable {
  final String name;
  final num amount;
  final num valorTotal;
  final Unit? unit;
  final String? rawUnitLabel;
  final String? produtoId;
  final String? codigo;
  final String? notaFiscalItemId;
  final double? recordedUnitPrice;
  final double? recordedTotalPrice;
  final String? matchingStatus;
  final PurchaseHistoryItemOrigin origin;

  const PurchaseHistoryItem({
    required this.name,
    required this.amount,
    required this.valorTotal,
    this.unit,
    this.rawUnitLabel,
    this.produtoId,
    this.codigo,
    this.notaFiscalItemId,
    this.recordedUnitPrice,
    this.recordedTotalPrice,
    this.matchingStatus,
    this.origin = PurchaseHistoryItemOrigin.cart,
  });

  factory PurchaseHistoryItem.fromMap(Map<String, dynamic> map) {
    // Para itens_nota_fiscal, o nome do produto vem da relação 'produtos'
    String productName = 'Item desconhecido';
    String? prodId;
    String? prodCodigo;
    String? rawUnitLabel;

    if (map['produtos'] != null) {
      productName = map['produtos']['nome'] as String;
      prodId = map['produtos']['id'] as String?;
      prodCodigo = map['produtos']['codigo'] as String?;
      rawUnitLabel = map['produtos']['unidade_medida'] as String?;
    } else if (map['name'] != null) {
      productName = map['name'] as String;
    }

    // Tenta carregar a unidade se disponível (vinda da tabela purchase_history_items)
    Unit? unit;
    if (map['units'] != null) {
      unit = Unit.fromMap(map['units'] as Map<String, dynamic>);
    }

    final recordedTotal =
        (map['recorded_total_price'] as num?)?.toDouble() ??
        (map['valor_total_item'] as num?)?.toDouble() ??
        0.0;

    final originValue = map['origin'] as String?;

    rawUnitLabel ??= map['raw_unit_label'] as String?;

    return PurchaseHistoryItem(
      name: productName,
      amount: (map['quantidade'] ?? map['amount'] ?? 0) as num,
      valorTotal: recordedTotal,
      unit: unit,
      rawUnitLabel: rawUnitLabel,
      produtoId: prodId,
      codigo: prodCodigo,
      notaFiscalItemId: map['nota_fiscal_item_id'] as String?,
      recordedUnitPrice: (map['recorded_unit_price'] as num?)?.toDouble(),
      recordedTotalPrice: (map['recorded_total_price'] as num?)?.toDouble(),
      matchingStatus: map['matching_status'] as String?,
      origin:
          originValue == 'invoice_extra'
              ? PurchaseHistoryItemOrigin.invoiceExtra
              : PurchaseHistoryItemOrigin.cart,
    );
  }

  bool get isInvoiceExtra => origin == PurchaseHistoryItemOrigin.invoiceExtra;

  String get unitLabel => unit?.abbreviation ?? rawUnitLabel ?? '';

  @override
  List<Object?> get props => [
    name,
    amount,
    valorTotal,
    unit,
    rawUnitLabel,
    produtoId,
    codigo,
    notaFiscalItemId,
    recordedUnitPrice,
    recordedTotalPrice,
    matchingStatus,
    origin,
  ];
}
