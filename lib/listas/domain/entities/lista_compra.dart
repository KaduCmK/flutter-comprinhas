import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

enum CartMode { shared, individual }

class ListaCompra extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final DateTime createdAt;
  final CartMode cartMode;

  const ListaCompra({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    this.cartMode = CartMode.shared,
  });

  String get createdAtFormatted => DateFormat('dd/MM/yyyy').format(createdAt);

  factory ListaCompra.fromMap(Map<String, dynamic> map) {
    return ListaCompra(
      id: map['id'] as String,
      name: map['name'] as String,
      ownerId: map['owner_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      cartMode: CartMode.values.firstWhere(
        (e) => e.name == map['cart_mode'],
        orElse: () => CartMode.shared,
      ),
    );
  }

  // toMap para inserts no Supabase
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'owner_id': ownerId,
      'cart_mode': cartMode.name, // CORREÇÃO: Usar .name ao invés de .toString()
    };
  }

  @override
  List<Object?> get props => [id, name, ownerId, createdAt, cartMode];
}