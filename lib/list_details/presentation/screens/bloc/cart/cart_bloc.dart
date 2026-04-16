import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/cart_item.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final ListasRepository _repository;
  final SupabaseClient _client;
  final String listId;
  final Future<bool> Function(String listItemId)? _isCurrentListItemOverride;
  final _logger = Logger();
  late final RealtimeChannel _cartChannel;

  CartBloc({
    required ListasRepository repository,
    required SupabaseClient client,
    required this.listId,
    Future<bool> Function(String listItemId)? isCurrentListItem,
  }) : _repository = repository,
       _client = client,
       _isCurrentListItemOverride = isCurrentListItem,
       super(const CartState()) {
    _setupRealtime();
    on<LoadCart>(_onLoadCart);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<SetCartMode>(_onSetCartMode);
    on<ConfirmPurchase>(_onConfirmPurchase);
  }

  Future<void> _onLoadCart(LoadCart event, Emitter<CartState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final items = await _repository.getCartItems(listId);
      emit(state.copyWith(isLoading: false, cartItems: items));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onAddToCart(AddToCart event, Emitter<CartState> emit) async {
    try {
      await _repository.addItemToCart(event.listItemId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onRemoveFromCart(
    RemoveFromCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      await _repository.removeItemFromCart(event.cartItemId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onSetCartMode(
    SetCartMode event,
    Emitter<CartState> emit,
  ) async {
    try {
      await _repository.setCartMode(listId, event.mode);
      emit(state.copyWith(cartMode: event.mode));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onConfirmPurchase(
    ConfirmPurchase event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      emit(state.copyWith(isLoading: false, error: 'Usuário não autenticado'));
      return;
    }

    List<CartItem> itemsToConfirm;
    if (state.cartMode == CartMode.individual) {
      itemsToConfirm =
          state.cartItems
              .where((item) => item.user.id == currentUserId)
              .toList();
    } else {
      itemsToConfirm = state.cartItems;
    }

    if (itemsToConfirm.isEmpty) {
      emit(state.copyWith(isLoading: false));
      return;
    }

    try {
      await _repository.confirmPurchase(
        itemsToConfirm.map((e) => e.id).toList(),
      );
      add(LoadCart()); // Recarrega o carrinho
    } catch (e) {
      _logger.e('Erro ao confirmar compra no BLoC: $e');
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Erro ao finalizar a compra. Tente novamente.',
        ),
      );
    }
  }

  void _setupRealtime() {
    _cartChannel = _client.channel('public:cart_items')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'cart_items',
        callback: (payload) async {
          if (isClosed) return;

          final shouldReload = await _shouldReloadForPayload(payload);
          if (shouldReload && !isClosed) add(LoadCart());
        },
      ).subscribe();
  }

  Future<bool> _shouldReloadForPayload(PostgresChangePayload payload) async {
    final listItemId = _extractAffectedListItemId(payload);
    if (listItemId == null) return false;

    final currentCartItemIds =
        state.cartItems.map((item) => item.listItem.id).toSet();
    if (currentCartItemIds.contains(listItemId)) return true;

    return _isCurrentListItem(listItemId);
  }

  String? _extractAffectedListItemId(PostgresChangePayload payload) {
    final newListItemId = payload.newRecord['list_item_id'];
    if (newListItemId is String && newListItemId.isNotEmpty) {
      return newListItemId;
    }

    final oldListItemId = payload.oldRecord['list_item_id'];
    if (oldListItemId is String && oldListItemId.isNotEmpty) {
      return oldListItemId;
    }

    return null;
  }

  Future<bool> _isCurrentListItem(String listItemId) async {
    final isCurrentListItemOverride = _isCurrentListItemOverride;
    if (isCurrentListItemOverride != null) {
      return isCurrentListItemOverride(listItemId);
    }

    try {
      final response =
          await _client
              .from('list_items')
              .select('list_id')
              .eq('id', listItemId)
              .maybeSingle();

      return response?['list_id'] == listId;
    } catch (e) {
      _logger.w('Erro ao validar escopo do realtime do carrinho: $e');
      return false;
    }
  }

  @override
  Future<void> close() {
    _client.removeChannel(_cartChannel);
    return super.close();
  }
}
