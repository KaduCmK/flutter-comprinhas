import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/listas/data/listas_repository_impl.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:flutter_comprinhas/shared/entities/unit.dart';

part 'listas_event.dart';
part 'listas_state.dart';

class ListasBloc extends Bloc<ListasEvent, ListasState> {
  final ListasRepository _repository;

  ListasBloc() : _repository = ListasRepositoryImpl(), super(ListasInitial()) {
    on<GetListsEvent>(_onGetLists);
    on<CreateListEvent>(_onCreateList);
  }

  Future<void> _onGetLists(
    GetListsEvent event,
    Emitter<ListasState> emit,
  ) async {
    emit(ListasLoading(lists: state.lists, units: state.units));

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
