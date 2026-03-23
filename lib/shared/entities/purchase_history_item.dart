import 'package:equatable/equatable.dart';
import 'package:flutter_comprinhas/shared/entities/unit.dart';

class PurchaseHistoryItem extends Equatable {
  final String name;
  final num amount;
  final num valorTotal;
  final Unit? unit;

  const PurchaseHistoryItem({
    required this.name,
    required this.amount,
    required this.valorTotal,
    this.unit,
  });

  factory PurchaseHistoryItem.fromMap(Map<String, dynamic> map) {
    // Para itens_nota_fiscal, o nome do produto vem da relação 'produtos'
    String productName = 'Item desconhecido';
    if (map['produtos'] != null) {
      productName = map['produtos']['nome'] as String;
    } else if (map['name'] != null) {
      productName = map['name'] as String;
    }

    // Tenta carregar a unidade se disponível (vinda da tabela purchase_history_items)
    Unit? unit;
    if (map['units'] != null) {
      unit = Unit.fromMap(map['units'] as Map<String, dynamic>);
    }

    return PurchaseHistoryItem(
      name: productName,
      amount: (map['quantidade'] ?? map['amount'] ?? 0) as num,
      valorTotal: (map['valor_total_item'] ?? 0) as num,
      unit: unit,
    );
  }

  @override
  List<Object?> get props => [name, amount, valorTotal, unit];
}
