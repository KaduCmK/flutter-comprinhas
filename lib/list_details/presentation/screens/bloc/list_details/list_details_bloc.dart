import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/cart_item.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/cart/cart_bloc.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:flutter_comprinhas/shared/entities/unit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'list_details_event.dart';
part 'list_details_state.dart';

class ListDetailsBloc extends Bloc<ListDetailsEvent, ListDetailsState> {
  final ListasRepository _repository;
  final SupabaseClient _client;
  final CartBloc _cartBloc;
  final String listId;
  StreamSubscription? _cartSubscription;

  List<ListItem> _originalItems = [];

  late final RealtimeChannel _itemChannel;

  ListDetailsBloc({
    required ListasRepository repository,
    required this.listId,
    required SupabaseClient client,
    required CartBloc cartBloc,
  })  : _repository = repository,
        _client = client,
        _cartBloc = cartBloc,
        super(ListDetailsState.initial()) {
    _setupRealtime();
    _cartSubscription = _cartBloc.stream.listen((cartState) {
      add(_CartUpdated(cartState.cartItems));
    });

    on<TogglePriceForecast>(_onTogglePriceForecast);
    on<LoadListDetails>(_onLoadListDetails);
    on<SortList>(_onSortList);
    on<AddItemToList>(_onAddItemToList);
    on<RemoveItemFromList>(_onRemoveItemFromList);
    on<_CartUpdated>(_onCartUpdated);
  }

  @override
  Future<void> close() {
    _client.removeChannel(_itemChannel);
    _cartSubscription?.cancel();
    return super.close();
  }

  void _filterAndSortItems(Emitter<ListDetailsState> emit) {
    final cartItemIds =
        _cartBloc.state.cartItems.map((item) => item.listItem.id).toSet();
    final itemsToBuy =
        _originalItems.where((item) => !cartItemIds.contains(item.id)).toList();
    final sortedItems = _sortItems(itemsToBuy, state.sortOption);
    emit(state.copyWith(items: sortedItems));
  }

  List<ListItem> _sortItems(List<ListItem> items, SortOption option) {
    final sortedList = List<ListItem>.from(items);
    switch (option) {
      case SortOption.name:
        sortedList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.date:
        sortedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return sortedList;
  }

  Future<void> _onLoadListDetails(
    LoadListDetails event,
    Emitter<ListDetailsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await _repository.getListById(listId);
      final units = await _repository.getUnits();
      _originalItems = await _repository.getListItems(listId);

      emit(state.copyWith(isLoading: false, list: list, units: units));
      _filterAndSortItems(emit);
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onSortList(
    SortList event,
    Emitter<ListDetailsState> emit,
  ) async {
    emit(state.copyWith(sortOption: event.sortOption));
    _filterAndSortItems(emit);
  }

  Future<void> _onAddItemToList(
    AddItemToList event,
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
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onRemoveItemFromList(
    RemoveItemFromList event,
    Emitter<ListDetailsState> emit,
  ) async {
    try {
      await _repository.removeItemFromList(event.itemId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onTogglePriceForecast(
    TogglePriceForecast event,
    Emitter<ListDetailsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.togglePriceForecast(listId, state.list!.priceForecastEnabled);
      add(LoadListDetails());
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _onCartUpdated(_CartUpdated event, Emitter<ListDetailsState> emit) {
    _filterAndSortItems(emit);
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
          if (!isClosed) add(LoadListDetails());
        },
      ).subscribe();
  }
}