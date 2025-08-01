import 'package:equatable/equatable.dart';
import 'package:flutter_comprinhas/shared/entities/purchase_history_item.dart';

class PurchaseHistory extends Equatable {
  final String id;
  final DateTime confirmedAt;
  final String? confirmedBy;
  final List<PurchaseHistoryItem> items;

  const PurchaseHistory({
    required this.id,
    required this.confirmedAt,
    this.confirmedBy,
    required this.items,
  });

  factory PurchaseHistory.fromMap(Map<String, dynamic> map) {
    String? userName;
    // Extrai o nome do usuário do campo 'raw_user_meta_data'
    if (map['users'] != null && map['users']['raw_user_meta_data'] != null) {
      userName = map['users']['raw_user_meta_data']['name'];
    }

    return PurchaseHistory(
      id: map['id'] as String,
      confirmedAt: DateTime.parse(map['created_at'] as String),
      confirmedBy: userName ?? 'Desconhecido',
      // Mapeia a lista de itens do histórico que vem aninhada na resposta
      items:
          (map['purchase_history_items'] as List<dynamic>)
              .map(
                (item) =>
                    PurchaseHistoryItem.fromMap(item as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  @override
  List<Object?> get props => [id, confirmedAt, confirmedBy, items];
}
