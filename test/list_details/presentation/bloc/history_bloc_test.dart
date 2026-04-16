import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/history/history_bloc.dart';
import 'package:flutter_comprinhas/shared/entities/purchase_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';

void main() {
  group('HistoryBloc', () {
    late MockListasRepository mockListasRepository;

    final history = [
      PurchaseHistory(
        id: 'purchase-1',
        confirmedAt: DateTime(2026, 4, 16, 10),
        items: const [],
        valorTotal: 22,
      ),
    ];

    setUp(() {
      mockListasRepository = MockListasRepository();
    });

    blocTest<HistoryBloc, HistoryState>(
      'carrega histórico de compras com sucesso',
      build: () {
        when(
          () => mockListasRepository.getPurchaseHistory('list-1'),
        ).thenAnswer((_) async => history);
        return HistoryBloc(repository: mockListasRepository, listId: 'list-1');
      },
      act: (bloc) => bloc.add(LoadHistory()),
      expect:
          () => [
            isA<HistoryState>().having(
              (state) => state.isLoading,
              'isLoading',
              true,
            ),
            isA<HistoryState>()
                .having((state) => state.isLoading, 'isLoading', false)
                .having(
                  (state) => state.purchaseHistory,
                  'purchaseHistory',
                  history,
                ),
          ],
    );

    blocTest<HistoryBloc, HistoryState>(
      'emite erro quando falha ao buscar histórico',
      build: () {
        when(
          () => mockListasRepository.getPurchaseHistory('list-1'),
        ).thenThrow(Exception('falha'));
        return HistoryBloc(repository: mockListasRepository, listId: 'list-1');
      },
      act: (bloc) => bloc.add(LoadHistory()),
      expect:
          () => [
            isA<HistoryState>().having(
              (state) => state.isLoading,
              'isLoading',
              true,
            ),
            isA<HistoryState>()
                .having((state) => state.isLoading, 'isLoading', false)
                .having((state) => state.error, 'error', 'Exception: falha'),
          ],
    );
  });
}
