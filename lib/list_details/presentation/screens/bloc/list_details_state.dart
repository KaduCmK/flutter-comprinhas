part of 'list_details_bloc.dart';

abstract class ListDetailsState extends Equatable {
  final ListaCompra? list;
  final List<Unit>? units;
  final List<ListItem> items;
  final List<CartItem> cartItems;
  final CartMode cartMode;
  final List<PurchaseHistory> purchaseHistory;

  const ListDetailsState({
    this.list,
    this.units,
    required this.items,
    required this.cartItems,
    this.cartMode = CartMode.shared,
    this.purchaseHistory = const [],
  });

  @override
  List<Object?> get props => [
    list,
    units,
    items,
    cartItems,
    cartMode,
    purchaseHistory,
  ];
}

class ListDetailsInitial extends ListDetailsState {
  const ListDetailsInitial() : super(items: const [], cartItems: const [], purchaseHistory: const []);
}

class ListDetailsLoading extends ListDetailsState {
  const ListDetailsLoading({
    super.list,
    super.units,
    required super.items,
    required super.cartItems,
    required super.cartMode,
    super.purchaseHistory,
  });
}

class ListDetailsLoaded extends ListDetailsState {
  const ListDetailsLoaded({
    required super.list,
    required super.units,
    required super.items,
    required super.cartItems,
    required super.cartMode,
    required super.purchaseHistory,
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
    super.purchaseHistory,
  });

  @override
  List<Object?> get props => [list, units, items, cartItems, cartMode, message];
}
