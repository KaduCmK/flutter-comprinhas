import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/cart_item.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:flutter_comprinhas/main.dart';
import 'package:flutter_comprinhas/shared/entities/unit.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListasRepositoryImpl implements ListasRepository {
  final _logger = Logger();
  late final SupabaseClient _client;

  ListasRepositoryImpl({required SupabaseClient client}) : _client = client;

  @override
  Future<List<ListaCompra>> getUserLists() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw 'Usuário não autenticado'; // TODO: implement failure cases
    }

    final fcmToken = await FirebaseMessaging.instance.getToken();
    await supabase
        .from('users')
        .update({'fcm_token': fcmToken})
        .eq('id', supabase.auth.currentUser!.id);

    try {
      final response = await _client
          .from('lists')
          .select('*, list_members!inner(*)')
          .eq('list_members.user_id', _client.auth.currentUser!.id);

      final lists = response.map((list) => ListaCompra.fromMap(list)).toList();
      return lists;
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> joinList(String listId) async {
    try {
      await _client.functions.invoke('join-list', body: {'list_id': listId});
    } catch (e) {
      debugPrint('Erro ao chamar edge function join_list: $e');
      rethrow;
    }
  }

  @override
  Future<ListaCompra> getListById(String listId) async {
    try {
      final response =
          await _client.from('lists').select().eq('id', listId).single();
      return ListaCompra.fromMap(response);
    } catch (e) {
      debugPrint('Erro ao buscar lista por id: $e');
      rethrow;
    }
  }

  @override
  Future<List<Unit>> getUnits() async {
    try {
      final response = await _client.from('units').select();
      final units = response.map((unit) => Unit.fromMap(unit)).toList();
      return units;
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
      await _client.from('lists').insert({'name': name});
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
            'id, created_at, name, amount, list:lists(*), created_by:created_by_id(*), unitId:unit_id',
          )
          .eq('list_id', listId);

      final items = response.map((e) => ListItem.fromMap(e)).toList();
      _logger.i(items);
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

  @override
  Future<void> removeItemFromList(String itemId) async {
    try {
      await _client.from('list_items').delete().eq('id', itemId);
    } catch (e) {
      debugPrint('Erro ao deletar item: $e');
      rethrow;
    }
  }

  @override
  Future<List<CartItem>> getCartItems(String? listId) async {
    try {
      var query = _client
          .from('cart_items')
          .select(
            '*, user:users(*), list_items!inner(*, list:lists(*), created_by:users(*))',
          );
      if (listId != null) {
        query = query.eq('list_items.list_id', listId);
      }
      final response = await query;

      final items =
          (response as List<dynamic>)
              .map((itemMap) => CartItem.fromMap(itemMap))
              .toList();
      return items;
    } catch (e) {
      _logger.e('erro ao buscar itens do carrinho: $e');
      rethrow;
    }
  }

  @override
  Future<void> addItemToCart(String listItemId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw 'Usuario nao autenticado';
    }

    try {
      await _client.from('cart_items').insert({
        'list_item_id': listItemId,
        'user_id': userId,
      });
    } catch (e) {
      debugPrint('Erro ao adicionar item ao carrinho: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeItemFromCart(String cartItemId) async {
    try {
      await _client.from('cart_items').delete().eq('id', cartItemId);
    } catch (e) {
      debugPrint('Erro ao remover item do carrinho: $e');
      rethrow;
    }
  }

  @override
  Future<void> setCartMode(String listId, CartMode mode) async {
    try {
      await _client
          .from('lists')
          .update({'cart_mode': mode.name})
          .eq('id', listId);
    } catch (e) {
      debugPrint('Erro ao atualizar modo do carrinho: $e');
      rethrow;
    }
  }
}
