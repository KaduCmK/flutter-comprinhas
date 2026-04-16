part of 'nfe_details_cubit.dart';

enum NfeDetailsStatus { idle, loadingMercado, readyToNavigate, error }

class NfeDetailsState extends Equatable {
  final NfeDetailsStatus status;
  final MercadoStats? mercadoStats;
  final String? errorMessage;

  const NfeDetailsState({
    this.status = NfeDetailsStatus.idle,
    this.mercadoStats,
    this.errorMessage,
  });

  bool get isLoadingMercado => status == NfeDetailsStatus.loadingMercado;

  NfeDetailsState copyWith({
    NfeDetailsStatus? status,
    MercadoStats? mercadoStats,
    bool clearMercadoStats = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return NfeDetailsState(
      status: status ?? this.status,
      mercadoStats:
          clearMercadoStats ? null : (mercadoStats ?? this.mercadoStats),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, mercadoStats, errorMessage];
}
