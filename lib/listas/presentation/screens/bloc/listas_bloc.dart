import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:flutter_comprinhas/main.dart';
import 'package:flutter_comprinhas/shared/entities/unit.dart';

part 'listas_event.dart';
part 'listas_state.dart';

class ListasBloc extends Bloc<ListasEvent, ListasState> {
  final ListasRepository _repository;

  ListasBloc({required ListasRepository repository})
    : _repository = repository,
      super(ListasInitial()) {
    on<GetListsEvent>(_onGetLists);
    on<CreateListEvent>(_onCreateList);
  }

  Future<void> _onGetLists(
    GetListsEvent event,
    Emitter<ListasState> emit,
  ) async {
    emit(ListasLoading(lists: state.lists, units: state.units));

    final fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint("fcm token: $fcmToken");
    await supabase
        .from('users')
        .update({'fcm_token': fcmToken})
        .eq('id', supabase.auth.currentUser!.id);

    try {
      final lists = await _repository.getUserLists();
      final units = await _repository.getUnits();
      emit(ListasLoaded(lists: lists, units: units));
    } catch (e) {
      emit(
        ListasError(
          lists: state.lists,
          units: state.units,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onCreateList(
    CreateListEvent event,
    Emitter<ListasState> emit,
  ) async {
    emit(ListasLoading(lists: state.lists, units: state.units));

    try {
      _repository.createList(event.name);
      final newLists = await _repository.getUserLists();
      emit(ListasLoaded(lists: newLists, units: state.units));
    } catch (e) {
      emit(
        ListasError(
          lists: state.lists,
          units: state.units,
          message: e.toString(),
        ),
      );
    }
  }
}
