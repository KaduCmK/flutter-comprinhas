import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/purchase_with_nfe_preview.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/close_purchase_with_nfe/close_purchase_with_nfe_cubit.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/close_purchase_with_nfe/close_purchase_with_nfe_state.dart';
import 'package:flutter_comprinhas/shared/entities/mercado.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';

void main() {
  group('ClosePurchaseWithNfeCubit', () {
    late MockListasRepository mockListasRepository;
    late PurchaseWithNfePreview preview;

    setUp(() {
      mockListasRepository = MockListasRepository();
      preview = PurchaseWithNfePreview(
        invoice: InvoicePreview(
          chaveAcesso: '1' * 44,
          dataEmissao: DateTime(2026, 4, 16, 10),
          mercado: const Mercado(id: 'mercado-1', nome: 'Mercado Teste'),
          valorTotal: 24.5,
          quantidadeItens: 1,
          items: const [],
        ),
        cartItems: const [
          CartReviewItem(
            cartItemId: 'cart-1',
            listItemId: 'list-item-1',
            name: 'Arroz',
            amount: 1,
            unitLabel: 'un',
            status: CartReviewStatus.ambiguous,
            selectedInvoiceItemTempId: null,
            selectedProductName: null,
            selectedSimilarity: null,
            recordedUnitPrice: null,
            recordedTotalPrice: null,
            candidates: [
              InvoiceMatchCandidate(
                invoiceItemTempId: 'nf-item-1',
                productName: 'Arroz Branco',
                unitLabel: 'un',
                quantity: 1,
                unitPrice: 10,
                totalPrice: 10,
                similarity: 0.95,
              ),
            ],
          ),
        ],
        extraItems: const [
          InvoiceExtraItem(
            invoiceItemTempId: 'nf-item-extra',
            productName: 'Feijão',
            quantity: 1,
            unitLabel: 'un',
            unitPrice: 8,
            totalPrice: 8,
          ),
        ],
        summary: const ReviewSummary(
          matchedItemsCount: 0,
          ambiguousItemsCount: 1,
          unmatchedItemsCount: 0,
          invoiceExtraItemsCount: 1,
        ),
      );
    });

    blocTest<ClosePurchaseWithNfeCubit, ClosePurchaseWithNfeState>(
      'emite falha quando a chave de acesso é inválida',
      build:
          () => ClosePurchaseWithNfeCubit(
            repository: mockListasRepository,
            cartItemIdsResolver: () => const ['cart-1'],
          ),
      act: (cubit) => cubit.loadPreview('123'),
      expect:
          () => [
            isA<ClosePurchaseWithNfeState>()
                .having(
                  (state) => state.status,
                  'status',
                  ClosePurchaseWithNfeStatus.failure,
                )
                .having(
                  (state) => state.errorMessage,
                  'errorMessage',
                  'Informe uma chave de acesso válida com 44 dígitos.',
                ),
          ],
      verify: (_) {
        verifyNever(
          () => mockListasRepository.previewPurchaseWithNfe(any(), any()),
        );
      },
    );

    blocTest<ClosePurchaseWithNfeCubit, ClosePurchaseWithNfeState>(
      'carrega preview e confirma a compra com match manual tratado',
      build: () {
        when(
          () => mockListasRepository.previewPurchaseWithNfe(any(), any()),
        ).thenAnswer((_) async => preview);
        when(
          () =>
              mockListasRepository.confirmPurchaseWithNfe(any(), any(), any()),
        ).thenAnswer((_) async {});
        return ClosePurchaseWithNfeCubit(
          repository: mockListasRepository,
          cartItemIdsResolver: () => const ['cart-1'],
        );
      },
      act: (cubit) async {
        await cubit.loadPreview('1' * 44);
        cubit.setManualMatch(
          'cart-1',
          ClosePurchaseWithNfeUi.ignoreCartItemSelection,
        );
        await cubit.confirmPurchase('1' * 44);
      },
      expect:
          () => [
            isA<ClosePurchaseWithNfeState>().having(
              (state) => state.status,
              'status',
              ClosePurchaseWithNfeStatus.loadingPreview,
            ),
            isA<ClosePurchaseWithNfeState>()
                .having(
                  (state) => state.status,
                  'status',
                  ClosePurchaseWithNfeStatus.previewReady,
                )
                .having((state) => state.preview, 'preview', preview),
            isA<ClosePurchaseWithNfeState>()
                .having(
                  (state) => state.manualMatches['cart-1'],
                  'manual match',
                  ClosePurchaseWithNfeUi.ignoreCartItemSelection,
                )
                .having((state) => state.canConfirm, 'canConfirm', true),
            isA<ClosePurchaseWithNfeState>().having(
              (state) => state.status,
              'status',
              ClosePurchaseWithNfeStatus.confirming,
            ),
            isA<ClosePurchaseWithNfeState>().having(
              (state) => state.status,
              'status',
              ClosePurchaseWithNfeStatus.success,
            ),
          ],
      verify: (_) {
        verify(
          () => mockListasRepository.confirmPurchaseWithNfe(
            const ['cart-1'],
            '1' * 44,
            {'cart-1': null},
          ),
        ).called(1);
      },
    );
  });
}
