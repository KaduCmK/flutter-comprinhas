import 'package:equatable/equatable.dart';
import 'package:flutter_comprinhas/shared/entities/mercado.dart';
import 'package:flutter_comprinhas/shared/entities/purchase_history_item.dart';

class PurchaseHistory extends Equatable {
  final String id;
  final DateTime confirmedAt;
  final DateTime? dataEmissao;
  final String? confirmedBy;
  final List<PurchaseHistoryItem> items;
  final double valorTotal;
  final Mercado? mercado;
  final String? chaveAcesso;
  final String? notaFiscalId;

  const PurchaseHistory({
    required this.id,
    required this.confirmedAt,
    this.dataEmissao,
    this.confirmedBy,
    required this.items,
    required this.valorTotal,
    this.mercado,
    this.chaveAcesso,
    this.notaFiscalId,
  });

  factory PurchaseHistory.fromMap(Map<String, dynamic> map) {
    String? userName;
    if (map['users'] != null && map['users']['user_metadata'] != null) {
      userName = map['users']['user_metadata']['name'];
    }

    final nestedNotaFiscal = map['notas_fiscais'] as Map<String, dynamic>?;
    final purchaseItems =
        (map['purchase_history_items'] as List<dynamic>?)
            ?.map(
              (item) =>
                  PurchaseHistoryItem.fromMap(item as Map<String, dynamic>),
            )
            .toList() ??
        [];
    final invoiceItems =
        (map['itens_nota_fiscal'] as List<dynamic>?)
            ?.map(
              (item) =>
                  PurchaseHistoryItem.fromMap(item as Map<String, dynamic>),
            )
            .toList() ??
        [];
    final allItems = purchaseItems.isNotEmpty ? purchaseItems : invoiceItems;
    final totalFromItems = allItems.fold<double>(
      0,
      (sum, item) => sum + item.valorTotal.toDouble(),
    );
    final mercadoMap =
        map['mercados'] as Map<String, dynamic>? ??
        nestedNotaFiscal?['mercados'] as Map<String, dynamic>?;
    final notaFiscalId =
        map['nota_fiscal_id'] as String? ?? nestedNotaFiscal?['id'] as String?;
    final valorTotal =
        (map['valor_total'] as num?)?.toDouble() ??
        (nestedNotaFiscal?['valor_total'] as num?)?.toDouble() ??
        totalFromItems;
    final rawDataEmissao =
        map['data_de_emissao'] as String? ??
        nestedNotaFiscal?['data_de_emissao'] as String?;
    final rawChaveAcesso =
        map['chave_acesso'] as String? ??
        nestedNotaFiscal?['chave_acesso'] as String?;

    return PurchaseHistory(
      id: map['id'] as String,
      confirmedAt: DateTime.parse(map['created_at'] as String),
      dataEmissao:
          rawDataEmissao != null ? DateTime.parse(rawDataEmissao) : null,
      confirmedBy: userName ?? 'Desconhecido',
      valorTotal: valorTotal,
      mercado: mercadoMap != null ? Mercado.fromMap(mercadoMap) : null,
      chaveAcesso: rawChaveAcesso,
      notaFiscalId: notaFiscalId,
      items: allItems,
    );
  }

  @override
  List<Object?> get props => [
    id,
    confirmedAt,
    dataEmissao,
    confirmedBy,
    items,
    valorTotal,
    mercado,
    chaveAcesso,
    notaFiscalId,
  ];
}
