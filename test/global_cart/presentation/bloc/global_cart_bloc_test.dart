import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_comprinhas/global_cart/presentation/bloc/global_cart_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';

void main() {
  group('GlobalCartBloc', () {
    late MockListasRepository mockListasRepository;

    setUp(() {
      mockListasRepository = MockListasRepository();
    });

    blocTest<GlobalCartBloc, GlobalCartState>(
      'carrega carrinho global com sucesso',
      build: () {
        when(
          () => mockListasRepository.getCartItems(null),
        ).thenAnswer((_) async => []);
        return GlobalCartBloc(repository: mockListasRepository);
      },
      act: (bloc) => bloc.add(LoadGlobalCartEvent()),
      expect:
          () => [
            isA<GlobalCartState>().having(
              (state) => state.isLoading,
              'isLoading',
              true,
            ),
            isA<GlobalCartState>()
                .having((state) => state.isLoading, 'isLoading', false)
                .having((state) => state.cartItems.length, 'cartItems', 0),
          ],
    );

    blocTest<GlobalCartBloc, GlobalCartState>(
      'emite erro quando falha ao carregar carrinho global',
      build: () {
        when(
          () => mockListasRepository.getCartItems(null),
        ).thenThrow(Exception('falha'));
        return GlobalCartBloc(repository: mockListasRepository);
      },
      act: (bloc) => bloc.add(LoadGlobalCartEvent()),
      expect:
          () => [
            isA<GlobalCartState>().having(
              (state) => state.isLoading,
              'isLoading',
              true,
            ),
            isA<GlobalCartState>().having(
              (state) => state.error,
              'error',
              'Exception: falha',
            ),
          ],
    );
  });
}
