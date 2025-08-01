import 'package:equatable/equatable.dart';

class PurchaseHistoryItem extends Equatable {
  final String name;
  final num amount;
  final String? unit;

  const PurchaseHistoryItem({
    required this.name,
    required this.amount,
    this.unit,
  });

  factory PurchaseHistoryItem.fromMap(Map<String, dynamic> map) {
    return PurchaseHistoryItem(
      name: map['name'] as String,
      amount: map['amount'] as num,
      unit: map['unit'] as String?,
    );
  }

  @override
  List<Object?> get props => [name, amount, unit];
}
