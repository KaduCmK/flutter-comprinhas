part of 'list_details_bloc.dart';

abstract class ListDetailsEvent extends Equatable {
  const ListDetailsEvent();

  @override
  List<Object> get props => [];
}

class LoadListDetails extends ListDetailsEvent {}

class SortList extends ListDetailsEvent {
  final SortOption sortOption;
  const SortList(this.sortOption);
  @override
  List<Object> get props => [sortOption];
}

class AddItemToList extends ListDetailsEvent {
  final String itemName;
  final num amount;
  final String unitId;

  const AddItemToList({
    required this.itemName,
    required this.amount,
    required this.unitId,
  });

  @override
  List<Object> get props => [itemName, amount, unitId];
}

class AddNaturalLanguageItemToList extends ListDetailsEvent {
  final String query;

  const AddNaturalLanguageItemToList(this.query);

  @override
  List<Object> get props => [query];
}

class RemoveItemFromList extends ListDetailsEvent {
  final String itemId;

  const RemoveItemFromList(this.itemId);

  @override
  List<Object> get props => [itemId];
}

class SugerirPreco extends ListDetailsEvent {
  final ListItem item;

  const SugerirPreco(this.item);

  @override
  List<Object> get props => [item];
}

class TogglePriceForecast extends ListDetailsEvent {}

class _CartUpdated extends ListDetailsEvent {
  final List<CartItem> cartItems;
  const _CartUpdated(this.cartItems);
}
