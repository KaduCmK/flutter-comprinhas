part of 'history_bloc.dart';

class HistoryState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<PurchaseHistory> purchaseHistory;

  const HistoryState({
    this.isLoading = false,
    this.error,
    this.purchaseHistory = const [],
  });

  HistoryState copyWith({
    bool? isLoading,
    String? error,
    List<PurchaseHistory>? purchaseHistory,
  }) {
    return HistoryState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      purchaseHistory: purchaseHistory ?? this.purchaseHistory,
    );
  }

  @override
  List<Object?> get props => [isLoading, error, purchaseHistory];
}