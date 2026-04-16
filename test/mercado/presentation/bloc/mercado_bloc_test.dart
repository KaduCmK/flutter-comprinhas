import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_repository.dart';
import 'package:flutter_comprinhas/mercado/presentation/bloc/mercado_bloc.dart';
import 'package:flutter_comprinhas/shared/entities/mercado.dart';
import 'package:flutter_comprinhas/shared/entities/purchase_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';

void main() {
  group('MercadoBloc', () {
    late MockMercadoRepository mockMercadoRepository;
    late MockNotificationService mockNotificationService;

    final history = [
      PurchaseHistory(
        id: 'purchase-1',
        confirmedAt: DateTime(2026, 4, 16, 10),
        items: const [],
        valorTotal: 25.5,
        mercado: const Mercado(id: 'mercado-1', nome: 'Mercado Teste'),
      ),
    ];

    final topMercados = [
      MercadoStats(
        mercado: const Mercado(id: 'mercado-1', nome: 'Mercado Teste'),
        totalNotas: 2,
        valorTotalGasto: 50,
      ),
    ];

    setUp(() {
      mockMercadoRepository = MockMercadoRepository();
      mockNotificationService = MockNotificationService();

      when(
        () => mockNotificationService.showPersistentNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockNotificationService.cancelNotification(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockNotificationService.showNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async {});
    });

    blocTest<MercadoBloc, MercadoState>(
      'carrega histórico e top mercados com sucesso',
      build: () {
        when(
          () => mockMercadoRepository.getNfeHistory(),
        ).thenAnswer((_) async => history);
        when(
          () => mockMercadoRepository.getTopMercados(),
        ).thenAnswer((_) async => topMercados);
        return MercadoBloc(
          mercadoRepository: mockMercadoRepository,
          notificationService: mockNotificationService,
        );
      },
      act: (bloc) => bloc.add(LoadNfeHistory()),
      expect:
          () => [
            isA<MercadoState>().having(
              (state) => state.status,
              'status',
              MercadoStatus.loading,
            ),
            isA<MercadoState>()
                .having(
                  (state) => state.status,
                  'status',
                  MercadoStatus.success,
                )
                .having((state) => state.history, 'history', history)
                .having(
                  (state) => state.topMercados,
                  'topMercados',
                  topMercados,
                ),
          ],
    );

    blocTest<MercadoBloc, MercadoState>(
      'rejeita chave inválida antes de enviar NF',
      build:
          () => MercadoBloc(
            mercadoRepository: mockMercadoRepository,
            notificationService: mockNotificationService,
          ),
      act: (bloc) => bloc.add(const SendNfe('123')),
      expect:
          () => [
            isA<MercadoState>()
                .having((state) => state.status, 'status', MercadoStatus.error)
                .having(
                  (state) => state.errorMessage,
                  'errorMessage',
                  'Chave de acesso com formato inválido recebida.',
                ),
          ],
      verify: (_) {
        verifyNever(() => mockMercadoRepository.sendNfe(any()));
      },
    );

    blocTest<MercadoBloc, MercadoState>(
      'envia NF com sucesso e recarrega histórico',
      build: () {
        when(
          () => mockMercadoRepository.sendNfe(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockMercadoRepository.getNfeHistory(),
        ).thenAnswer((_) async => history);
        when(
          () => mockMercadoRepository.getTopMercados(),
        ).thenAnswer((_) async => topMercados);
        return MercadoBloc(
          mercadoRepository: mockMercadoRepository,
          notificationService: mockNotificationService,
        );
      },
      act: (bloc) => bloc.add(SendNfe('1' * 44)),
      expect:
          () => [
            isA<MercadoState>().having(
              (state) => state.status,
              'status',
              MercadoStatus.sending,
            ),
            isA<MercadoState>().having(
              (state) => state.status,
              'status',
              MercadoStatus.sent,
            ),
            isA<MercadoState>().having(
              (state) => state.status,
              'status',
              MercadoStatus.loading,
            ),
            isA<MercadoState>().having(
              (state) => state.status,
              'status',
              MercadoStatus.success,
            ),
          ],
      verify: (_) {
        verify(
          () => mockNotificationService.showPersistentNotification(
            id: 0,
            title: 'Enviando Nota Fiscal',
            body: 'Aguarde enquanto processamos a sua nota fiscal.',
          ),
        ).called(1);
        verify(() => mockNotificationService.cancelNotification(0)).called(1);
      },
    );
  });
}
