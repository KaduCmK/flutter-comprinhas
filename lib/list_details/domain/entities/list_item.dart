import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';

class ListItem extends Equatable {
  final String id;
  final String name;
  final num amount;
  final String unitId;
  final User createdBy;
  final DateTime createdAt;
  final ListaCompra list; // MUDANÇA PRINCIPAL: De listId para um objeto ListaCompra

  const ListItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.unitId,
    required this.createdBy,
    required this.createdAt,
    required this.list, // MUDANÇA PRINCIPAL
  });

  factory ListItem.fromMap(Map<String, dynamic> map) {
    // Sua classe original já esperava um objeto 'created_by'
    // O JSON que vc mandou só tem 'created_by_id'
    // Pra fazer funcionar, sua query precisa buscar o usuário completo.
    // Ex: .select('*, list_items(*, list:lists(*), created_by:users(*))')
    
    return ListItem(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: map['amount'] as num,
      unitId: map['unit_id'] as String, // CORREÇÃO: snake_case
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
      'unit_id': unitId,
      'list_id': list.id,
      'created_by_id': createdBy.id,
    };
  }

  @override
  List<Object?> get props => [id, name, amount, unitId, createdBy, createdAt, list];
}