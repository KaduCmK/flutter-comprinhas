import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/listas/data/listas_repository_impl.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';

part 'list_details_event.dart';
part 'list_details_state.dart';

class ListDetailsBloc extends Bloc<ListDetailsEvent, ListDetailsState> {
  final ListasRepository _repository = ListasRepositoryImpl();
  final ListaCompra list;

  ListDetailsBloc({required this.list}) : super(ListDetailsInitial(list)) {
    on<LoadListItemsEvent>(_onLoadListItems);
    on<AddItemToListEvent>(_onAddItemToList);
  }

  Future<void> _onLoadListItems(
    LoadListItemsEvent event,
    Emitter<ListDetailsState> emit,
  ) async {}

  Future<void> _onAddItemToList(
    AddItemToListEvent event,
    Emitter<ListDetailsState> emit,
  ) async {}
}
