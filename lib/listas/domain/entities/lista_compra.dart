import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum CartMode { shared, individual }

class ListMember extends Equatable {
  final User user;
  final DateTime joinedAt;

  const ListMember({required this.user, required this.joinedAt});

  factory ListMember.fromMap(Map<String, dynamic> map) {
    return ListMember(
      user: User.fromJson(map['users'] as Map<String, dynamic>)!,
      joinedAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [user, joinedAt];
}

class ListaCompra extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final DateTime createdAt;
  final CartMode cartMode;
  final bool priceForecastEnabled;
  final List<ListMember> members;

  const ListaCompra({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    this.cartMode = CartMode.shared,
    this.priceForecastEnabled = false,
    this.members = const [],
  });

  String get createdAtFormatted => DateFormat('dd/MM/yyyy').format(createdAt);

  factory ListaCompra.fromMap(Map<String, dynamic> map) {
    final membersList = (map['list_members'] as List<dynamic>?)
            ?.map((e) => ListMember.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ListaCompra(
      id: map['id'] as String,
      name: map['name'] as String,
      ownerId: map['owner_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      cartMode: CartMode.values.firstWhere(
        (e) => e.name == map['cart_mode'],
        orElse: () => CartMode.shared,
      ),
      priceForecastEnabled: map['price_forecast_enabled'] as bool? ?? false,
      members: membersList,
    );
  }

  // toMap para inserts no Supabase
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'owner_id': ownerId,
      'cart_mode': cartMode.name,
      'price_forecast_enabled': priceForecastEnabled,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    ownerId,
    createdAt,
    cartMode,
    priceForecastEnabled,
    members,
  ];
}
