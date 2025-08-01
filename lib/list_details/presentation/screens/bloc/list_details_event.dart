part of 'list_details_bloc.dart';

abstract class ListDetailsEvent extends Equatable {
  const ListDetailsEvent();

  @override
  List<Object> get props => [];
}

class LoadListDetailsEvent extends ListDetailsEvent {}

class AddItemToListEvent extends ListDetailsEvent {
  final String itemName;
  final num amount;
  final String unitId;

  const AddItemToListEvent({
    required this.itemName,
    required this.amount,
    required this.unitId,
  });

  @override
  List<Object> get props => [itemName, amount, unitId];
}

class RemoveItemFromListEvent extends ListDetailsEvent {
  final String itemId;

  const RemoveItemFromListEvent(this.itemId);

  @override
  List<Object> get props => [itemId];
}

class AddToCartEvent extends ListDetailsEvent {
  final String listItemId;

  const AddToCartEvent(this.listItemId);

  @override
  List<Object> get props => [listItemId];
}

class RemoveFromCartEvent extends ListDetailsEvent {
  final String cartItemId;

  const RemoveFromCartEvent(this.cartItemId);

  @override
  List<Object> get props => [cartItemId];
}

class SetCartModeEvent extends ListDetailsEvent {
  final CartMode? mode;

  const SetCartModeEvent({this.mode});

  @override
  List<Object> get props => [mode ?? CartMode.shared];
}

class ConfirmPurchaseEvent extends ListDetailsEvent {}