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
  final _logger = Logger();
  late final RealtimeChannel _cartChannel;

  CartBloc({
    required ListasRepository repository,
    required SupabaseClient client,
    required this.listId,
  })  : _repository = repository,
        _client = client,
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

  Future<void> _onSetCartMode(SetCartMode event, Emitter<CartState> emit) async {
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
      emit(state.copyWith(
          isLoading: false, error: 'Usuário não autenticado'));
      return;
    }

    List<CartItem> itemsToConfirm;
    if (state.cartMode == CartMode.individual) {
      itemsToConfirm = state.cartItems
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
      await _repository.confirmPurchase(itemsToConfirm.map((e) => e.id).toList());
      add(LoadCart()); // Recarrega o carrinho
    } catch (e) {
      _logger.e('Erro ao confirmar compra no BLoC: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Erro ao finalizar a compra. Tente novamente.',
      ));
    }
  }

  void _setupRealtime() {
    _cartChannel = _client.channel('public:cart_items')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'cart_items',
        callback: (payload) {
          if (!isClosed) add(LoadCart());
        },
      ).subscribe();
  }

  @override
  Future<void> close() {
    _client.removeChannel(_cartChannel);
    return super.close();
  }
}