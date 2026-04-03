part of 'list_details_bloc.dart';

enum SortOption { name, date, price }

enum SortOrder { ascending, descending }

class ListDetailsState extends Equatable {
  final bool isLoading;
  final bool isParsingNlp;
  final String? suggestingPriceItemId;
  final String? error;
  final ListaCompra? list;
  final List<Unit>? units;
  final List<ListItem> items;
  final SortOption sortOption;
  final SortOrder sortOrder;

  const ListDetailsState({
    this.isLoading = false,
    this.isParsingNlp = false,
    this.suggestingPriceItemId,
    this.error,
    this.list,
    this.units,
    this.items = const [],
    this.sortOption = SortOption.date,
    this.sortOrder = SortOrder.descending,
  });

  factory ListDetailsState.initial() {
    return const ListDetailsState();
  }

  ListDetailsState copyWith({
    bool? isLoading,
    bool? isParsingNlp,
    String? suggestingPriceItemId,
    String? error,
    ListaCompra? list,
    List<Unit>? units,
    List<ListItem>? items,
    SortOption? sortOption,
    SortOrder? sortOrder,
  }) {
    return ListDetailsState(
      isLoading: isLoading ?? this.isLoading,
      isParsingNlp: isParsingNlp ?? this.isParsingNlp,
      suggestingPriceItemId: suggestingPriceItemId,
      error: error,
      list: list ?? this.list,
      units: units ?? this.units,
      items: items ?? this.items,
      sortOption: sortOption ?? this.sortOption,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  double get estimatedTotal {
    double total = 0.0;
    for (var item in items) {
      if (item.precoSugerido != null) {
        double multiplier = 1.0;
        if (item.unidadePrecoSugerido != null) {
          multiplier = UnitConverter.getConversionFactor(
            item.unit.abbreviation,
            item.unidadePrecoSugerido!,
          );
        }
        total += (item.precoSugerido! * multiplier * item.amount);
      }
    }
    return total;
  }

  @override
  List<Object?> get props => [
    isLoading,
    isParsingNlp,
    suggestingPriceItemId,
    error,
    list,
    units,
    items,
    sortOption,
    sortOrder,
  ];
}
