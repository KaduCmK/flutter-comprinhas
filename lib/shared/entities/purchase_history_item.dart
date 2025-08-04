import 'package:equatable/equatable.dart';
import 'package:flutter_comprinhas/shared/entities/unit.dart';

class PurchaseHistoryItem extends Equatable {
  final String name;
  final num amount;
  final Unit? unit;

  const PurchaseHistoryItem({
    required this.name,
    required this.amount,
    this.unit,
  });

  factory PurchaseHistoryItem.fromMap(Map<String, dynamic> map) {
    return PurchaseHistoryItem(
      name: map['name'] as String,
      amount: map['amount'] as num,
      unit: (Unit.fromMap(map['units'])) as Unit?,
    );
  }

  @override
  List<Object?> get props => [name, amount, unit];
}
