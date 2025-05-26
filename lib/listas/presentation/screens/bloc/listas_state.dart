part of 'listas_bloc.dart';

abstract class ListasState extends Equatable {
  final List<ListaCompra> lists;

  const ListasState(this.lists);

  @override
  List<Object?> get props => [lists];
}

class ListasInitial extends ListasState {
  ListasInitial() : super(List.empty());
}

class ListasLoading extends ListasState {
  const ListasLoading(super.lists);
}

class ListasLoaded extends ListasState {
  const ListasLoaded(super.lists);
}

class ListasError extends ListasState {
  final String message;

  const ListasError(super.lists, {required this.message});

  @override
  List<Object?> get props => [lists, message];
}
