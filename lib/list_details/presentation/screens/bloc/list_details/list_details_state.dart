part of 'list_details_bloc.dart';

enum SortOption { name, date}

class ListDetailsState extends Equatable {
  final bool isLoading;
  final String? error;
  final ListaCompra? list;
  final List<Unit>? units;
  final List<ListItem> items;
  final SortOption sortOption;

  const ListDetailsState({
    this.isLoading = false,
    this.error,
    this.list,
    this.units,
    this.items = const [],
    this.sortOption = SortOption.name,
  });

  factory ListDetailsState.initial() {
    return const ListDetailsState();
  }

  ListDetailsState copyWith({
    bool? isLoading,
    String? error,
    ListaCompra? list,
    List<Unit>? units,
    List<ListItem>? items,
    SortOption? sortOption,
  }) {
    return ListDetailsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      list: list ?? this.list,
      units: units ?? this.units,
      items: items ?? this.items,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        error,
        list,
        units,
        items,
        sortOption,
      ];
}