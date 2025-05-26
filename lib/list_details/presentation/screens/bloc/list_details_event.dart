part of 'list_details_bloc.dart';

abstract class ListDetailsEvent extends Equatable {
  const ListDetailsEvent();

  @override
  List<Object> get props => [];
}

class LoadListItemsEvent extends ListDetailsEvent {
  final String listId;

  const LoadListItemsEvent(this.listId);

  @override
  List<Object> get props => [listId];
}

class AddItemToListEvent extends ListDetailsEvent {
  final String listId;
  final String itemName;

  const AddItemToListEvent(this.listId, this.itemName);

  @override
  List<Object> get props => [listId, itemName];
}

class DeleteItemFromListEvent extends ListDetailsEvent {
  final String listId;
  final String itemId;

  const DeleteItemFromListEvent(this.listId, this.itemId);

  @override
  List<Object> get props => [listId, itemId];
}
