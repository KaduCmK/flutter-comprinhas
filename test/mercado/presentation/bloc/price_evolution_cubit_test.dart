import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_comprinhas/mercado/presentation/bloc/price_evolution_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';

void main() {
  group('PriceEvolutionCubit', () {
    late MockMercadoRepository mockMercadoRepository;

    setUp(() {
      mockMercadoRepository = MockMercadoRepository();
    });

    blocTest<PriceEvolutionCubit, PriceEvolutionState>(
      'carrega histórico de preços com sucesso',
      build: () {
        when(
          () => mockMercadoRepository.getProductPriceHistory('produto-1'),
        ).thenAnswer(
          (_) async => [
            {'data': DateTime(2026, 4, 10), 'preco_unitario': 10.5},
          ],
        );
        return PriceEvolutionCubit(mercadoRepository: mockMercadoRepository);
      },
      act: (cubit) => cubit.load('produto-1'),
      expect:
          () => [
            isA<PriceEvolutionState>().having(
              (state) => state.status,
              'status',
              PriceEvolutionStatus.loading,
            ),
            isA<PriceEvolutionState>()
                .having(
                  (state) => state.status,
                  'status',
                  PriceEvolutionStatus.success,
                )
                .having((state) => state.history.length, 'history length', 1),
          ],
    );

    blocTest<PriceEvolutionCubit, PriceEvolutionState>(
      'emite erro quando falha ao buscar histórico',
      build: () {
        when(
          () => mockMercadoRepository.getProductPriceHistory('produto-1'),
        ).thenThrow(Exception('falha'));
        return PriceEvolutionCubit(mercadoRepository: mockMercadoRepository);
      },
      act: (cubit) => cubit.load('produto-1'),
      expect:
          () => [
            isA<PriceEvolutionState>().having(
              (state) => state.status,
              'status',
              PriceEvolutionStatus.loading,
            ),
            isA<PriceEvolutionState>()
                .having(
                  (state) => state.status,
                  'status',
                  PriceEvolutionStatus.error,
                )
                .having(
                  (state) => state.errorMessage,
                  'errorMessage',
                  'Exception: falha',
                ),
          ],
    );
  });
}
