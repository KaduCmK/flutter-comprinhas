import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/cart_item.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:flutter_comprinhas/shared/entities/purchase_history.dart';
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
    on<SortListEvent>(_onSortList);
    on<LoadPurchaseHistoryEvent>(_onLoadPurchaseHistory);
    on<AddItemToListEvent>(_onAddItemToList);
    on<RemoveItemFromListEvent>(_onRemoveItemFromList);
    on<AddToCartEvent>(_onAddToCart);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<SetCartModeEvent>(_onSetCartMode);
    on<ConfirmPurchaseEvent>(_onConfirmPurchase);
  }

  @override
  Future<void> close() {
    _closeRealtime();
    return super.close();
  }

  List<ListItem> _sortItems(List<ListItem> items, SortOption option) {
    final sortedList = List<ListItem>.from(
      items,
    ); // Crie uma cópia para não modificar a original
    switch (option) {
      case SortOption.name:
        sortedList.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case SortOption.date:
        sortedList.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        ); // Mais novo primeiro
        break;
    }
    return sortedList;
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
        purchaseHistory: state.purchaseHistory,
        sortOption: state.sortOption,
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
          cartItems.map((cartItem) => cartItem.listItem.id).toSet();
      final itemsToBuy =
          allItems.where((item) => !cartItemIds.contains(item.id)).toList();

      final sortedItems = _sortItems(itemsToBuy, state.sortOption);

      emit(
        ListDetailsLoaded(
          list: list,
          units: units,
          items: sortedItems,
          cartItems: cartItems,
          cartMode: list.cartMode,
          purchaseHistory: state.purchaseHistory,
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
          sortOption: state.sortOption,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSortList(
    SortListEvent event,
    Emitter<ListDetailsState> emit,
  ) async {
    if (state is ListDetailsLoaded) {
      final currentState = state as ListDetailsLoaded;
      final sortedItems = _sortItems(currentState.items, event.sortOption);

      emit(
        ListDetailsLoaded(
          list: currentState.list,
          units: currentState.units,
          items: sortedItems,
          cartItems: currentState.cartItems,
          cartMode: currentState.cartMode,
          sortOption: event.sortOption,
          purchaseHistory: currentState.purchaseHistory,
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
      _logger.e(e);
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

  Future<void> _onSetCartMode(
    SetCartModeEvent event,
    Emitter<ListDetailsState> emit,
  ) async {
    final newMode = event.mode ?? CartMode.shared;
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

  Future<void> _onConfirmPurchase(
    ConfirmPurchaseEvent event,
    Emitter<ListDetailsState> emit,
  ) async {
    emit(
      ListDetailsLoading(
        list: state.list,
        items: state.items,
        units: state.units,
        cartItems: state.cartItems,
        cartMode: state.cartMode,
      ),
    );
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw 'Usuario nao autenticado';
    }

    List<CartItem> itemsToConfirm;

    // Lógica principal: decidir quais itens confirmar com base no modo do carrinho
    if (state.cartMode == CartMode.individual) {
      // Modo individual: pega apenas os itens que o usuário logado adicionou
      itemsToConfirm =
          state.cartItems
              .where((item) => item.user.id == currentUserId)
              .toList();
    } else {
      // Modo compartilhado: pega TODOS os itens da cesta
      itemsToConfirm = state.cartItems;
    }

    final cartIdsToConfirm = itemsToConfirm.map((item) => item.id).toList();

    // Se não tiver itens (ex: modo individual e o usuário não adicionou nada), não faz nada.
    if (cartIdsToConfirm.isEmpty) return;

    try {
      await _repository.confirmPurchase(cartIdsToConfirm);
      // Após confirmar, recarrega a tela para atualizar a lista de itens e o carrinho
      add(LoadListDetailsEvent());
    } catch (e) {
      _logger.e('Erro ao confirmar compra no BLoC: $e');
      emit(
        ListDetailsError(
          list: state.list,
          units: state.units,
          items: state.items,
          cartItems: state.cartItems,
          cartMode: state.cartMode,
          message: 'Erro ao finalizar a compra. Tente novamente.',
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

  _onLoadPurchaseHistory(
    LoadPurchaseHistoryEvent event,
    Emitter<ListDetailsState> emit,
  ) async {
    emit(
      ListDetailsLoading(
        items: state.items,
        cartItems: state.cartItems,
        cartMode: state.cartMode,
        units: state.units,
        list: state.list,
        purchaseHistory: state.purchaseHistory,
      ),
    );
    try {
      final history = await _repository.getPurchaseHistory(listId);
      emit(
        ListDetailsLoaded(
          list: state.list,
          units: state.units,
          items: state.items,
          cartItems: state.cartItems,
          cartMode: state.cartMode,
          purchaseHistory: history,
        ),
      );
    } catch (e) {
      emit(
        ListDetailsError(
          items: state.items,
          cartItems: state.cartItems,
          cartMode: state.cartMode,
          message: e.toString(),
        ),
      );
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
