import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_repository.dart';
import 'package:flutter_comprinhas/mercado/presentation/bloc/nfe_details_cubit.dart';
import 'package:flutter_comprinhas/shared/entities/mercado.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';

void main() {
  group('NfeDetailsCubit', () {
    late MockMercadoRepository mockMercadoRepository;
    late MercadoStats mercadoStats;

    setUp(() {
      mockMercadoRepository = MockMercadoRepository();
      mercadoStats = MercadoStats(
        mercado: const Mercado(id: 'mercado-1', nome: 'Mercado Teste'),
        totalNotas: 3,
        valorTotalGasto: 120,
      );
    });

    blocTest<NfeDetailsCubit, NfeDetailsState>(
      'carrega mercado e emite estado de navegação',
      build: () {
        when(
          () => mockMercadoRepository.getMercadoStatsById('mercado-1'),
        ).thenAnswer((_) async => mercadoStats);
        return NfeDetailsCubit(mercadoRepository: mockMercadoRepository);
      },
      act: (cubit) => cubit.loadMercadoDetails('mercado-1'),
      expect:
          () => [
            isA<NfeDetailsState>().having(
              (state) => state.status,
              'status',
              NfeDetailsStatus.loadingMercado,
            ),
            isA<NfeDetailsState>()
                .having(
                  (state) => state.status,
                  'status',
                  NfeDetailsStatus.readyToNavigate,
                )
                .having(
                  (state) => state.mercadoStats,
                  'mercadoStats',
                  mercadoStats,
                ),
          ],
    );

    blocTest<NfeDetailsCubit, NfeDetailsState>(
      'emite erro quando não encontra estatísticas do mercado',
      build: () {
        when(
          () => mockMercadoRepository.getMercadoStatsById('mercado-1'),
        ).thenAnswer((_) async => null);
        return NfeDetailsCubit(mercadoRepository: mockMercadoRepository);
      },
      act: (cubit) => cubit.loadMercadoDetails('mercado-1'),
      expect:
          () => [
            isA<NfeDetailsState>().having(
              (state) => state.status,
              'status',
              NfeDetailsStatus.loadingMercado,
            ),
            isA<NfeDetailsState>()
                .having(
                  (state) => state.status,
                  'status',
                  NfeDetailsStatus.error,
                )
                .having(
                  (state) => state.errorMessage,
                  'errorMessage',
                  'Não foi possível carregar os dados do mercado.',
                ),
          ],
    );
  });
}
