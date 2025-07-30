part of 'list_details_bloc.dart';

abstract class ListDetailsState extends Equatable {
  final ListaCompra? list;
  final List<Unit>? units;
  final List<ListItem> items;
  final List<CartItem> cartItems;
  final CartMode cartMode;

  const ListDetailsState({
    this.list,
    this.units,
    required this.items,
    required this.cartItems,
    this.cartMode = CartMode.shared,
  });

  @override
  List<Object?> get props => [list, units, items, cartItems, cartMode];
}

class ListDetailsInitial extends ListDetailsState {
  const ListDetailsInitial() : super(items: const [], cartItems: const []);
}

class ListDetailsLoading extends ListDetailsState {
  const ListDetailsLoading({
    super.list,
    super.units,
    required super.items,
    required super.cartItems,
    required super.cartMode,
  });
}

class ListDetailsLoaded extends ListDetailsState {
  const ListDetailsLoaded({
    required super.list,
    required super.units,
    required super.items,
    required super.cartItems,
    required super.cartMode,
  });
}

class ListDetailsError extends ListDetailsState {
  final String message;

  const ListDetailsError({
    super.list,
    super.units,
    required super.items,
    required super.cartItems,
    required super.cartMode,
    required this.message,
  });

  @override
  List<Object?> get props => [list, units, items, cartItems, cartMode, message];
}
