import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_repository.dart';

part 'nfe_details_state.dart';

class NfeDetailsCubit extends Cubit<NfeDetailsState> {
  final MercadoRepository _repository;

  NfeDetailsCubit({required MercadoRepository mercadoRepository})
    : _repository = mercadoRepository,
      super(const NfeDetailsState());

  Future<void> loadMercadoDetails(String mercadoId) async {
    emit(
      state.copyWith(
        status: NfeDetailsStatus.loadingMercado,
        clearErrorMessage: true,
        clearMercadoStats: true,
      ),
    );

    try {
      final stats = await _repository.getMercadoStatsById(mercadoId);
      if (stats == null) {
        emit(
          state.copyWith(
            status: NfeDetailsStatus.error,
            errorMessage: 'Não foi possível carregar os dados do mercado.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: NfeDetailsStatus.readyToNavigate,
          mercadoStats: stats,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NfeDetailsStatus.error,
          errorMessage: 'Erro ao carregar dados do mercado: $e',
        ),
      );
    }
  }

  void clearTransientState() {
    emit(
      state.copyWith(
        status: NfeDetailsStatus.idle,
        clearErrorMessage: true,
        clearMercadoStats: true,
      ),
    );
  }
}
