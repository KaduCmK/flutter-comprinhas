import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/cart_item.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:flutter_comprinhas/shared/entities/unit.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'list_details_event.dart';
part 'list_details_state.dart';

class ListDetailsBloc extends Bloc<ListDetailsEvent, ListDetailsState> {
  final Logger _logger = Logger();
  final ListasRepository _repository;
  final SupabaseClient _client;
  final String listId;

  // Getter para a lista original, antes do filtro do carrinho
  List<ListItem> originalItems = [];

  late final RealtimeChannel _itemChannel;
  late final RealtimeChannel _cartChannel;

  ListDetailsBloc({
    required ListasRepository repository,
    required this.listId,
    required SupabaseClient client,
  }) : _repository = repository,
       _client = client,
       super(const ListDetailsInitial()) {
    _setupRealtime();

    on<LoadListDetailsEvent>(_onLoadListDetails);
    on<AddItemToListEvent>(_onAddItemToList);
    on<RemoveItemFromListEvent>(_onRemoveItemFromList);
    on<AddToCartEvent>(_onAddToCart);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<ToggleCartModeEvent>(_onToggleCartMode);
  }

  @override
  Future<void> close() {
    _closeRealtime();
    return super.close();
  }

  Future<void> _onLoadListDetails(
    LoadListDetailsEvent event,
    Emitter<ListDetailsState> emit,
  ) async {
    emit(
      ListDetailsLoading(
        list: state.list,
        units: state.units,
        items: state.items,
        cartItems: state.cartItems,
        cartMode: state.cartMode,
      ),
    );
    try {
      final list = await _repository.getListById(listId);
      final units = await _repository.getUnits();
      final allItems = await _repository.getListItems(listId);
      final cartItems = await _repository.getCartItems(listId);

      // Guarda a lista completa antes de filtrar
      originalItems = allItems;

      // Filtra os itens que já estão no carrinho para não exibi-los na lista principal
      final cartItemIds =
          cartItems.map((cartItem) => cartItem.listItemId).toSet();
      final itemsToBuy =
          allItems.where((item) => !cartItemIds.contains(item.id)).toList();

      emit(
        ListDetailsLoaded(
          list: list,
          units: units,
          items: itemsToBuy,
          cartItems: cartItems,
          cartMode: list.cartMode,
        ),
      );
    } catch (e) {
      emit(
        ListDetailsError(
          list: state.list,
          units: state.units,
          items: state.items,
          cartItems: state.cartItems,
          cartMode: state.cartMode,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onAddToCart(
    AddToCartEvent event,
    Emitter<ListDetailsState> emit,
  ) async {
    try {
      await _repository.addItemToCart(event.listItemId);
    } catch (e) {
      // Opcional: Tratar erro, talvez emitindo um estado de erro específico.
    }
  }

  Future<void> _onRemoveFromCart(
    RemoveFromCartEvent event,
    Emitter<ListDetailsState> emit,
  ) async {
    try {
      await _repository.removeItemFromCart(event.cartItemId);
    } catch (e) {
      // Opcional: Tratar erro.
    }
  }

  Future<void> _onToggleCartMode(
    ToggleCartModeEvent event,
    Emitter<ListDetailsState> emit,
  ) async {
    final newMode =
        state.cartMode == CartMode.shared
            ? CartMode.individual
            : CartMode.shared;
    try {
      await _repository.setCartMode(listId, newMode);
      add(LoadListDetailsEvent());
    } catch (e) {
      _logger.e('Erro ao alternar modo de carrinho: $e');
      emit(
        ListDetailsError(
          list: state.list,
          units: state.units,
          items: state.items,
          cartItems: state.cartItems,
          cartMode: state.cartMode,
          message: 'Erro ao alternar modo de carrinho: $e',
        ),
      );
    }
  }

  Future<void> _onAddItemToList(
    AddItemToListEvent event,
    Emitter<ListDetailsState> emit,
  ) async {
    try {
      await _repository.addItemToList(
        listId,
        event.itemName,
        event.amount,
        event.unitId,
      );
    } catch (e) {
      // ... tratamento de erro
    }
  }

  Future<void> _onRemoveItemFromList(
    RemoveItemFromListEvent event,
    Emitter<ListDetailsState> emit,
  ) async {
    try {
      await _repository.removeItemFromList(event.itemId);
    } catch (e) {
      // ... tratamento de erro
    }
  }

  void _setupRealtime() {
    _itemChannel = _client.channel('public:list_items:list_id=eq.$listId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'list_items',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'list_id',
          value: listId,
        ),
        callback: (payload) {
          if (!isClosed) add(LoadListDetailsEvent());
        },
      ).subscribe();

    _cartChannel = _client.channel('public:cart_items')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'cart_items',
        callback: (payload) {
          if (!isClosed) add(LoadListDetailsEvent());
        },
      ).subscribe();
  }

  void _closeRealtime() {
    _client.removeChannel(_itemChannel);
    _client.removeChannel(_cartChannel);
  }
}
