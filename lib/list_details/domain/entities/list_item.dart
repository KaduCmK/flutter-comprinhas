import 'package:equatable/equatable.dart';
import 'package:flutter_comprinhas/shared/entities/unit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';

class ListItem extends Equatable {
  final String id;
  final String name;
  final num amount;
  final Unit unit;
  final User createdBy;
  final DateTime createdAt;
  final ListaCompra list;

  const ListItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    required this.createdBy,
    required this.createdAt,
    required this.list,
  });

  factory ListItem.fromMap(Map<String, dynamic> map) {
    return ListItem(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: map['amount'] as num,
      unit: Unit.fromMap(map['units'] as Map<String, dynamic>),
      createdBy: User.fromJson(map['created_by'] as Map<String, dynamic>)!,
      createdAt: DateTime.parse(map['created_at'] as String),
      // MUDANÇA PRINCIPAL: Mapeia o objeto aninhado 'list'
      list: ListaCompra.fromMap(map['list'] as Map<String, dynamic>),
    );
  }

  // toMap para inserts no Supabase
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'amount': amount,
      'unit_id': unit.id,
      'list_id': list.id,
      'created_by_id': createdBy.id,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    amount,
    unit,
    createdBy,
    createdAt,
    list,
  ];
}
