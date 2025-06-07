import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final ListaCompra list;
  final List<Unit> units;

  late final RealtimeChannel _itemChannel;

  ListDetailsBloc({
    required ListasRepository repository,
    required this.list,
    required this.units,
  }) : _repository = repository,
       super(ListDetailsInitial(list, units)) {
    _setupRealtime();

    on<LoadListItemsEvent>(_onLoadListItems);
    on<AddItemToListEvent>(_onAddItemToList);
  }

  @override
  Future<void> close() {
    _closeRealtime();
    return super.close();
  }

  Future<void> _onLoadListItems(
    LoadListItemsEvent event,
    Emitter<ListDetailsState> emit,
  ) async {
    // emit(ListDetailsLoading(list: state.list, items: state.items));
    try {
      final items = await _repository.getListItems(list.id);
      emit(ListDetailsLoaded(list: state.list, units: units, items: items));
    } catch (e) {
      emit(
        ListDetailsError(
          list: state.list,
          items: state.items,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onAddItemToList(
    AddItemToListEvent event,
    Emitter<ListDetailsState> emit,
  ) async {
    emit(ListDetailsLoading(list: list, items: state.items));
    try {
      await _repository.addItemToList(
        list.id,
        event.itemName,
        event.amount,
        event.unitId,
      );
      // final newItems = await _repository.getListItems(list.id);
      // emit(ListDetailsLoaded(list: list, units: units, items: newItems));
    } catch (e) {
      emit(
        ListDetailsError(items: state.items, list: list, message: e.toString()),
      );
    }
  }

  void _setupRealtime() {
    _itemChannel = supabase.channel('public:list_items:list_id=eq.${list.id}');
    debugPrint('list id: ${list.id}');

    _itemChannel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'list_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'list_id',
            value: list.id,
          ),
          callback: (payload) {
            debugPrint('>>> Realtime event received: ${payload.toString()}');
            if (!isClosed) {
              add(const LoadListItemsEvent());
            }
          },
        )
        .subscribe();
        debugPrint('>>> Realtime channel subscribed');
  }

  void _closeRealtime() {
    _itemChannel.unsubscribe();
    debugPrint('>>> Realtime channel unsubscribed');
  }
}
