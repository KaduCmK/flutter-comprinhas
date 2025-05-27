// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListItem extends Equatable {
  final String id;
  final DateTime createdAt;
  final String name;
  final num amount;
  final String listId;
  final User createdBy;
  final String unitId;

  const ListItem({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.amount,
    required this.listId,
    required this.createdBy,
    required this.unitId,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'createdAt': createdAt.toString(),
      'name': name,
      'amount': amount,
      'listId': listId,
      'createdBy': createdBy.toJson(),
      'unitId': unitId,
    };
  }

  factory ListItem.fromMap(Map<String, dynamic> map) {
    return ListItem(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      name: map['name'] as String,
      amount: map['amount'] as num,
      listId: map['list_id'] as String,
      createdBy: User.fromJson(map['created_by'] as Map<String, dynamic>)!,
      unitId: map['unitId'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory ListItem.fromJson(String source) =>
      ListItem.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
    id,
    name,
    amount,
    createdBy,
    createdAt,
    listId,
    unitId,
  ];
}
