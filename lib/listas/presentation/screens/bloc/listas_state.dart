part of 'listas_bloc.dart';

abstract class ListasState extends Equatable {
  const ListasState();

  @override
  List<Object?> get props => [];
}

class ListasInitial extends ListasState {}

class ListasLoading extends ListasState {
  final List<ListaCompra> listas;

  const ListasLoading(this.listas);

  @override
  List<Object?> get props => [listas];
}

class ListasLoaded extends ListasState {
  final List<ListaCompra> listas;

  const ListasLoaded(this.listas);

  @override
  List<Object?> get props => [listas];
}

class ListasError extends ListasState {
  final List<ListaCompra> listas;
  final String message;

  const ListasError(this.listas, this.message);

  @override
  List<Object?> get props => [listas, message];
}
