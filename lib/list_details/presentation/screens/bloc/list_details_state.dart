part of 'list_details_bloc.dart';

abstract class ListDetailsState extends Equatable {
  final ListaCompra? list;
  final List<Unit>? units;
  final List<ListItem> items;

  const ListDetailsState({this.list, this.units, required this.items});

  @override
  List<Object?> get props => [list, units, items];
}

class ListDetailsInitial extends ListDetailsState {
  const ListDetailsInitial() : super(items: const []);
}

class ListDetailsLoading extends ListDetailsState {
  const ListDetailsLoading({super.list, super.units, required super.items});
}

class ListDetailsLoaded extends ListDetailsState {
  const ListDetailsLoaded({
    required super.list,
    required super.units,
    required super.items,
  });
}

class ListDetailsError extends ListDetailsState {
  final String message;

  const ListDetailsError({
    super.list,
    super.units,
    required super.items,
    required this.message,
  });

  @override
  List<Object?> get props => [list, units, items, message];
}
