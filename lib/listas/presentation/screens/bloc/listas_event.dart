part of 'listas_bloc.dart';

abstract class ListasEvent extends Equatable {
  const ListasEvent();

  @override
  List<Object?> get props => [];
}

class GetListsEvent extends ListasEvent {}

class UpsertListEvent extends ListasEvent {
  final String name;
  final String? listId;

  const UpsertListEvent(this.name, {this.listId});

  @override
  List<Object?> get props => [name, listId];
}

class DeleteListEvent extends ListasEvent {
  final String listId;

  const DeleteListEvent(this.listId);

  @override
  List<Object> get props => [listId];
}
