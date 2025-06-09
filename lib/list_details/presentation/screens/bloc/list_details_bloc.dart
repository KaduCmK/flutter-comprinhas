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
  final String listId;

  late final RealtimeChannel _itemChannel;

  ListDetailsBloc({required ListasRepository repository, required this.listId})
    : _repository = repository,
      super(ListDetailsInitial()) {
    _setupRealtime();

    on<LoadListDetailsEvent>(_onLoadListDetails);
    on<AddItemToListEvent>(_onAddItemToList);
    on<RemoveItemFromListEvent>(_onRemoveItemFromList);
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
      ),
    );
    try {
      final list = await _repository.getListById(listId);
      final units = await _repository.getUnits();
      final items = await _repository.getListItems(listId);
      debugPrint('items: ${items.length}');
      emit(ListDetailsLoaded(list: list, units: units, items: items));
    } catch (e) {
      emit(
        ListDetailsError(
          list: state.list,
          units: state.units,
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
    emit(
      ListDetailsLoading(
        items: state.items,
        list: state.list,
        units: state.units,
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
          message: e.toString(),
        ),
      );
    }
  }

  void _setupRealtime() {
    _itemChannel = supabase.channel('public:list_items:list_id=eq.$listId');
    debugPrint('list id: $listId');

    _itemChannel
        .onPostgresChanges(
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
        )
        .subscribe();
    debugPrint('>>> Realtime channel subscribed');
  }

  void _closeRealtime() {
    _itemChannel.unsubscribe();
    debugPrint('>>> Realtime channel unsubscribed');
  }
}
