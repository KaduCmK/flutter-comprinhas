part of 'mercado_bloc.dart';

enum MercadoStatus { initial, loading, success, error, sending, sent }

final class MercadoState extends Equatable {
  final MercadoStatus status;
  final List<PurchaseHistory> history;
  final String? errorMessage;

  const MercadoState({
    this.status = MercadoStatus.initial,
    this.history = const [],
    this.errorMessage,
  });

  MercadoState copyWith({
    MercadoStatus? status,
    List<PurchaseHistory>? history,
    String? errorMessage,
  }) {
    return MercadoState(
      status: status ?? this.status,
      history: history ?? this.history,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, history, errorMessage];
}
