part of 'mercado_bloc.dart';

enum MercadoStatus { initial, loading, success, error, sending, sent }

final class MercadoState extends Equatable {
  final MercadoStatus status;
  final List<PurchaseHistory> history;
  final List<MercadoStats> topMercados;
  final String? errorMessage;

  const MercadoState({
    this.status = MercadoStatus.initial,
    this.history = const [],
    this.topMercados = const [],
    this.errorMessage,
  });

  MercadoState copyWith({
    MercadoStatus? status,
    List<PurchaseHistory>? history,
    List<MercadoStats>? topMercados,
    String? errorMessage,
  }) {
    return MercadoState(
      status: status ?? this.status,
      history: history ?? this.history,
      topMercados: topMercados ?? this.topMercados,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, history, topMercados, errorMessage];
}
