part of 'listas_bloc.dart';

abstract class ListasState extends Equatable {
  final List<ListaCompra> lists;
  final List<Unit> units; // Added units field

  const ListasState({required this.lists, required this.units});

  @override
  List<Object?> get props => [lists, units];
}

class ListasInitial extends ListasState {
  ListasInitial() : super(lists: [], units: []); // Initialize with empty units
}

class ListasLoading extends ListasState {
  const ListasLoading({required super.lists, required super.units});
}

class ListasLoaded extends ListasState {
  const ListasLoaded({required super.lists, required super.units});
}

class ListasError extends ListasState {
  final String message;
  const ListasError({
    required super.lists,
    required super.units,
    required this.message,
  });

  @override
  List<Object?> get props => [lists, units, message];
}