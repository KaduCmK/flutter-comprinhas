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

  const PurchaseHistory({
    required this.id,
    required this.confirmedAt,
    this.dataEmissao,
    this.confirmedBy,
    required this.items,
    required this.valorTotal,
    this.mercado,
    this.chaveAcesso,
  });

  factory PurchaseHistory.fromMap(Map<String, dynamic> map) {
    String? userName;
    if (map['users'] != null && map['users']['user_metadata'] != null) {
      userName = map['users']['user_metadata']['name'];
    }

    // A estrutura do Supabase para notas_fiscais usa 'data_de_emissao' ou 'created_at'
    // E os itens vêm de 'itens_nota_fiscal'
    return PurchaseHistory(
      id: map['id'] as String,
      confirmedAt: DateTime.parse(map['created_at'] as String),
      dataEmissao: map['data_de_emissao'] != null ? DateTime.parse(map['data_de_emissao'] as String) : null,
      confirmedBy: userName ?? 'Desconhecido',
      valorTotal: (map['valor_total'] as num).toDouble(),
      mercado: map['mercados'] != null ? Mercado.fromMap(map['mercados']) : null,
      chaveAcesso: map['chave_acesso'] as String?,
      items:
          (map['itens_nota_fiscal'] as List<dynamic>?)
              ?.map(
                (item) =>
                    PurchaseHistoryItem.fromMap(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [id, confirmedAt, dataEmissao, confirmedBy, items, valorTotal, mercado, chaveAcesso];
}
