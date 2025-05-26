part of 'list_details_bloc.dart';

abstract class ListDetailsState extends Equatable {
  final ListaCompra? list;
  final List<ListItem> items;

  const ListDetailsState({this.list, required this.items});

  @override
  List<Object?> get props => [list, items];
}

class ListDetailsInitial extends ListDetailsState {
  final ListaCompra initialList;

  const ListDetailsInitial(this.initialList)
    : super(list: initialList, items: const []);
}

class ListDetailsLoading extends ListDetailsState {
  const ListDetailsLoading({super.list, required super.items});
}

class ListDetailsLoaded extends ListDetailsState {
  const ListDetailsLoaded({required super.list, required super.items});
}

class ListDetailsError extends ListDetailsState {
  final String message;

  const ListDetailsError({
    super.list,
    required super.items,
    required this.message,
  });

  @override
  List<Object?> get props => [list, items, message];
}
