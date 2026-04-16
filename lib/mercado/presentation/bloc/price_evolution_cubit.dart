import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_repository.dart';

part 'price_evolution_state.dart';

class PriceEvolutionCubit extends Cubit<PriceEvolutionState> {
  final MercadoRepository _repository;

  PriceEvolutionCubit({required MercadoRepository mercadoRepository})
    : _repository = mercadoRepository,
      super(const PriceEvolutionState());

  Future<void> load(String produtoId) async {
    emit(
      state.copyWith(
        status: PriceEvolutionStatus.loading,
        clearErrorMessage: true,
      ),
    );

    try {
      final history = await _repository.getProductPriceHistory(produtoId);
      emit(
        state.copyWith(
          status: PriceEvolutionStatus.success,
          history: history,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PriceEvolutionStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
