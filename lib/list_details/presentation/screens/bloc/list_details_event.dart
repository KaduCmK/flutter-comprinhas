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

class DeleteItemFromListEvent extends ListDetailsEvent {
  final String listId;
  final String itemId;

  const DeleteItemFromListEvent(this.listId, this.itemId);

  @override
  List<Object> get props => [listId, itemId];
}
