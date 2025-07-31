import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

enum CartMode { shared, individual }

class ListaCompra extends Equatable {
  final String id;
  final String name;
  final DateTime _createdAt;
  final CartMode cartMode;

  const ListaCompra({
    required this.id,
    required this.name,
    required DateTime createdAt,
    this.cartMode = CartMode.shared,
  }) : _createdAt = createdAt;

  String get createdAt => DateFormat('dd/MM/yyyy').format(_createdAt);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'createdAt': _createdAt.toString(),
      'cart_mode': cartMode.toString(),
    };
  }

  factory ListaCompra.fromMap(Map<String, dynamic> map) {
    return ListaCompra(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      cartMode: CartMode.values.firstWhere(
        (e) => e.name == map['cart_mode'],
        orElse: () => CartMode.shared,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory ListaCompra.fromJson(String source) =>
      ListaCompra.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [id, name, _createdAt, cartMode];
}
