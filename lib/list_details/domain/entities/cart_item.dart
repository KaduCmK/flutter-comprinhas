// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartItem extends Equatable {
  final String id;
  final String listItemId;
  final User user;
  final DateTime addedAt;

  const CartItem({
    required this.id,
    required this.listItemId,
    required this.user,
    required this.addedAt,
  });

  @override
  List<Object?> get props => [id, listItemId, user, addedAt];

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as String,
      listItemId: map['list_item_id'] as String,
      user: User.fromJson(map['user'] as Map<String, dynamic>)!,
      addedAt: DateTime.parse(map['added_at'] as String),
    );
  }

  
}
