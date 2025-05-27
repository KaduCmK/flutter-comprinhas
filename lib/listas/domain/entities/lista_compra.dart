// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class ListaCompra extends Equatable {
  final String id;
  final String name;
  final DateTime _createdAt;

  const ListaCompra({
    required this.id,
    required this.name,
    required DateTime createdAt,
  }) : _createdAt = createdAt;

  String get createdAt => DateFormat('dd/MM/yyyy').format(_createdAt);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'createdAt': _createdAt.toString(),
    };
  }

  factory ListaCompra.fromMap(Map<String, dynamic> map) {
    return ListaCompra(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory ListaCompra.fromJson(String source) =>
      ListaCompra.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [id, name, _createdAt];
}
