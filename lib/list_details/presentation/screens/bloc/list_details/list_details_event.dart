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

class RemoveItemFromList extends ListDetailsEvent {
  final String itemId;
  const RemoveItemFromList(this.itemId);
  @override
  List<Object> get props => [itemId];
}

class TogglePriceForecast extends ListDetailsEvent {}

class _CartUpdated extends ListDetailsEvent {
  final List<CartItem> cartItems;
  const _CartUpdated(this.cartItems);
}