import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';

part 'listas_event.dart';
part 'listas_state.dart';

class ListasBloc extends Bloc<ListasEvent, ListasState> {
  ListasBloc() : super(ListasInitial()) {
    on<ListasEvent>((event, emit) {
    });
  }
}
