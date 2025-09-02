part of 'list_details_bloc.dart';

enum SortOption { name, date }

abstract class ListDetailsState extends Equatable {
  final ListaCompra? list;
  final List<Unit>? units;
  final List<ListItem> items;
  final List<CartItem> cartItems;
  final CartMode cartMode;
  final List<PurchaseHistory> purchaseHistory;
  final SortOption sortOption;

  const ListDetailsState({
    this.list,
    this.units,
    required this.items,
    required this.cartItems,
    this.cartMode = CartMode.shared,
    this.purchaseHistory = const [],
    this.sortOption = SortOption.name,
  });

  @override
  List<Object?> get props => [
    list,
    units,
    items,
    cartItems,
    cartMode,
    purchaseHistory,
    sortOption,
  ];
}

class ListDetailsInitial extends ListDetailsState {
  const ListDetailsInitial()
    : super(items: const [], cartItems: const [], purchaseHistory: const []);
}

class ListDetailsLoading extends ListDetailsState {
  const ListDetailsLoading({
    super.list,
    super.units,
    required super.items,
    required super.cartItems,
    required super.cartMode,
    super.purchaseHistory,
    super.sortOption,
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
    super.sortOption,
  });

  @override
  List<Object?> get props => [
    list,
    units,
    items,
    cartItems,
    cartMode,
    purchaseHistory,
    sortOption,
  ];
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
    super.sortOption,
  });

  @override
  List<Object?> get props => [
    list,
    units,
    items,
    cartItems,
    cartMode,
    message,
    purchaseHistory,
    sortOption,
  ];
}
