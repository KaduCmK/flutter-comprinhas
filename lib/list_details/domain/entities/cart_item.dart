import 'package:equatable/equatable.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartItem extends Equatable {
  final String id;
  final User user;
  final DateTime addedAt;
  final ListItem listItem;

  const CartItem({
    required this.id,
    required this.user,
    required this.addedAt,
    required this.listItem,
  });

  String get listName => listItem.list.name;

  @override
  List<Object> get props => [id, user, addedAt, listItem];

  // O fromMap pode continuar como está, pois agora ele assume que 'list_items' sempre existirá
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as String,
      addedAt: DateTime.parse(map['added_at'] as String),
      user: User.fromJson(map['user'] as Map<String, dynamic>)!,
      listItem: ListItem.fromMap(map['list_items'] as Map<String, dynamic>),
    );
  }
}