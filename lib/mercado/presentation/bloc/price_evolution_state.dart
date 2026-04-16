part of 'price_evolution_cubit.dart';

enum PriceEvolutionStatus { initial, loading, success, error }

class PriceEvolutionState extends Equatable {
  final PriceEvolutionStatus status;
  final List<Map<String, dynamic>> history;
  final String? errorMessage;

  const PriceEvolutionState({
    this.status = PriceEvolutionStatus.initial,
    this.history = const [],
    this.errorMessage,
  });

  PriceEvolutionState copyWith({
    PriceEvolutionStatus? status,
    List<Map<String, dynamic>>? history,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PriceEvolutionState(
      status: status ?? this.status,
      history: history ?? this.history,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, history, errorMessage];
}
