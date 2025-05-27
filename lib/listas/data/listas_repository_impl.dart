import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListasRepositoryImpl implements ListasRepository {
  late final SupabaseClient _client;

  ListasRepositoryImpl() : _client = Supabase.instance.client;

  @override
  Future<List<ListaCompra>> getUserLists() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw 'Usuário não autenticado'; // TODO: implement failure cases
    }

    try {
      final response = await _client
          .from('lists')
          .select()
          .eq('owner_id', userId);

      final lists = response.map((list) => ListaCompra.fromMap(list)).toList();
      return lists;
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> createList(String name) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw 'Usuario nao autenticado'; // TODO: implement failure cases
    }

    try {
      await _client.from('lists').insert({'name': name, 'owner_id': userId});
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  @override
  Future<List<ListItem>> getListItems(String listId) async {
    try {
      final response = await _client
          .from('list_items')
          .select(
            'id, created_at, name, amount, list_id, created_by:created_by_id(*), unitId:unit_id',
          )
          .eq('list_id', listId);
      final items = response.map((e) => ListItem.fromMap(e)).toList();
      return items;
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> addItemToList(
    String listId,
    String name,
    num amount,
    String unitId,
  ) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw 'Usuario nao autenticado';
    }

    final Map<String, dynamic> dbRecord = {
      'name': name,
      'amount': amount,
      'list_id': listId,
      'unit_id': unitId,
    };

    try {
      await _client.from('list_items').insert(dbRecord);
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
