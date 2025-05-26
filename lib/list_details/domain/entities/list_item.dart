import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListItem extends Equatable {
  final String id;
  final String name;
  final User createdBy;
  final DateTime createdAt;
  final String listId;

  const ListItem({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.listId,
  });

  @override
  List<Object?> get props => [id, name, createdBy, createdAt, listId];
}
