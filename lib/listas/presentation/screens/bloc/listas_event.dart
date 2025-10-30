part of 'listas_bloc.dart';

abstract class ListasEvent extends Equatable {
  const ListasEvent();

  @override
  List<Object> get props => [];
}

class GetListsEvent extends ListasEvent {}

class CreateListEvent extends ListasEvent {
  final String name;

  const CreateListEvent(this.name);

  @override
  List<Object> get props => [name];
}

class DeleteListEvent extends ListasEvent {
  final String listId;

  const DeleteListEvent(this.listId);

  @override
  List<Object> get props => [listId];
}

