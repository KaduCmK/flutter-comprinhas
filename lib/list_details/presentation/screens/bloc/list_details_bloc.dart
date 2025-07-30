import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/cart_item.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:flutter_comprinhas/main.dart';
import 'package:flutter_comprinhas/shared/entities/unit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'list_details_event.dart';
part 'list_details_state.dart';

class ListDetailsBloc extends Bloc<ListDetailsEvent, ListDetailsState> {
  final ListasRepository _repository;
  final String listId;

  late final RealtimeChannel _itemChannel;
  late final RealtimeChannel _cartChannel;

  ListDetailsBloc({required ListasRepository repository, required this.listId})
    : _repository = repository,
      super(ListDetailsInitial()) {
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
      final items = await _repository.getListItems(listId);
      final units = await _repository.getUnits();
      final cartItems = await _repository.getCartItems(listId);

      final cartItemIds = cartItems.map((item) => item.listItemId).toSet();
      final itemsToBuy =
          items.where((item) => !cartItemIds.contains(item.id)).toList();

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

  Future<void> _onAddItemToList(
    AddItemToListEvent event,
    Emitter<ListDetailsState> emit,
  ) async {
    emit(
      ListDetailsLoading(
        items: state.items,
        list: state.list,
        units: state.units,
        cartItems: state.cartItems,
        cartMode: state.cartMode,
      ),
    );
    try {
      await _repository.addItemToList(
        listId,
        event.itemName,
        event.amount,
        event.unitId,
      );
    } catch (e) {
      emit(
        ListDetailsError(
          items: state.items,
          list: state.list,
          units: state.units,
          cartItems: state.cartItems,
          cartMode: state.cartMode,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRemoveItemFromList(
    RemoveItemFromListEvent event,
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
      await _repository.removeItemFromList(event.itemId);
    } catch (e) {
      emit(
        ListDetailsError(
          items: state.items,
          list: state.list,
          units: state.units,
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
      emit(
        ListDetailsError(
          items: state.items,
          list: state.list,
          units: state.units,
          cartItems: state.cartItems,
          cartMode: state.cartMode,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRemoveFromCart(
    RemoveFromCartEvent event,
    Emitter<ListDetailsState> emit,
  ) async {
    try {
      await _repository.removeItemFromCart(event.listItemId);
    } catch (e) {
      emit(
        ListDetailsError(
          items: state.items,
          list: state.list,
          units: state.units,
          cartItems: state.cartItems,
          cartMode: state.cartMode,
          message: e.toString(),
        ),
      );
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
      emit(
        ListDetailsError(
          items: state.items,
          list: state.list,
          units: state.units,
          cartItems: state.cartItems,
          cartMode: state.cartMode,
          message: e.toString(),
        ),
      );
    }
  }

  void _setupRealtime() {
    _itemChannel = supabase.channel('public:list_items:list_id=eq.$listId')
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
          debugPrint('>>> Realtime event received: ${payload.toString()}');
          if (!isClosed) {
            add(LoadListDetailsEvent());
          }
        },
      ).subscribe();

    _cartChannel = supabase.channel('public:cart_items:list_id=eq.$listId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'cart_items',
        callback: (payload) {
          if (!isClosed) add(LoadListDetailsEvent());
        },
      ).subscribe();

    debugPrint('>>> Realtime channel subscribed');
  }

  void _closeRealtime() {
    _itemChannel.unsubscribe();
    _cartChannel.unsubscribe();
    debugPrint('>>> Realtime channel unsubscribed');
  }
}
