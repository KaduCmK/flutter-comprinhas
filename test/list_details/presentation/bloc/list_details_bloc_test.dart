import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/cart_item.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details/list_details_bloc.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../mocks.dart';

class MockUser extends Mock implements User {}

void main() {
  setUpAll(() {
    registerFallbackValue(CartMode.shared);
  });

  group('ListDetailsBloc', () {
    late MockListasRepository mockListasRepository;
    late CartBloc listDetailsBloc;
    late ListaCompra mockList;
    late List<ListItem> mockItems;
    late User mockUser;

    const listId = 'list-1';

    setUp(() {
      mockListasRepository = MockListasRepository();
      mockUser = MockUser();

      when(() => mockUser.id).thenReturn('user-123');
      when(() => mockUser.toJson()).thenReturn({
        'id': 'user-123',
        'email': 'test@test.com',
        'app_metadata': {},
        'user_metadata': {},
        'aud': 'aud',
        'created_at': DateTime.now().toIso8601String(),
      });

      mockList = ListaCompra(
        id: listId,
        name: 'Test List',
        createdAt: DateTime.now(),
        cartMode: CartMode.shared,
      );
      mockItems = [
        ListItem(
          id: 'item-1',
          name: 'Item 1',
          amount: 1,
          listId: listId,
          createdAt: DateTime.now(),
          createdBy: mockUser,
          unitId: 'un',
        ),
        ListItem(
          id: 'item-2',
          name: 'Item 2',
          amount: 2,
          listId: listId,
          createdAt: DateTime.now(),
          createdBy: mockUser,
          unitId: 'un',
        ),
      ];

      // Configuração padrão dos mocks do repositório
      when(
        () => mockListasRepository.getListById(any()),
      ).thenAnswer((_) async => mockList);
      when(
        () => mockListasRepository.getListItems(any()),
      ).thenAnswer((_) async => mockItems);
      when(
        () => mockListasRepository.getCartItems(any()),
      ).thenAnswer((_) async => []);
      when(() => mockListasRepository.getUnits()).thenAnswer((_) async => []);
      when(
        () => mockListasRepository.setCartMode(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => mockListasRepository.addItemToCart(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockListasRepository.removeItemFromCart(any()),
      ).thenAnswer((_) async {});

      listDetailsBloc = CartBloc(
        client: Supabase.instance.client,
        repository: mockListasRepository,
        listId: listId,
      );
    });

    test('Estado inicial deve ser ListDetailsInitial', () {
      expect(listDetailsBloc.state, isA<ListDetailsInitial>());
    });

    blocTest<CartBloc, ListDetailsState>(
      'deve emitir ListDetailsLoaded',
      build: () => listDetailsBloc,
      act: (bloc) => bloc.add(LoadListDetailsEvent()),
      expect: () => [isA<ListDetailsLoading>(), isA<ListDetailsLoaded>()],
      verify: (_) {
        verify(() => mockListasRepository.getListById(listId)).called(1);
        verify(() => mockListasRepository.getListItems(listId)).called(1);
        verify(() => mockListasRepository.getCartItems(listId)).called(1);
      },
    );

    // bateria de testes para funcionalidade do carrinho
    group('Funcionalidade do Carrinho', () {
      blocTest<CartBloc, ListDetailsState>(
        'deve chamar o repositório para adicionar item ao carrinho',
        build: () => listDetailsBloc,
        act: (bloc) => bloc.add(const AddToCartEvent('item-1')),
        verify: (_) {
          verify(() => mockListasRepository.addItemToCart('item-1')).called(1);
        },
      );

      blocTest<CartBloc, ListDetailsState>(
        'deve chamar o repositório para remover o item do carrinho',
        build: () => listDetailsBloc,
        act: (bloc) => bloc.add(const RemoveFromCartEvent('cart-item-1')),
        verify: (_) {
          verify(
            () => mockListasRepository.removeItemFromCart('cart-item-1'),
          ).called(1);
        },
      );

      blocTest<CartBloc, ListDetailsState>(
        'deve alternar o modo do carrinho de compartilhado para individual',
        build: () => listDetailsBloc,
        // Estado inicial simulado
        seed:
            () => ListDetailsLoaded(
              list: mockList,
              items: mockItems,
              units: [],
              cartItems: [],
              cartMode: CartMode.shared,
            ),
        act: (bloc) => bloc.add(SetCartModeEvent()),
        verify: (_) {
          // Verifica se o método para mudar o modo no backend foi chamado com o valor correto
          verify(
            () => mockListasRepository.setCartMode(listId, CartMode.individual),
          ).called(1);
        },
      );

      // Teste crucial da regra de negócio
      blocTest<CartBloc, ListDetailsState>(
        'deve remover um item da lista de compras quando ele está no carrinho',
        setUp: () {
          // Arrange: Prepara um cenário específico para este teste
          final itemInCart = ListItem(
            id: 'item-1',
            name: 'No Carrinho',
            amount: 1,
            listId: listId,
            createdAt: DateTime.now(),
            createdBy: mockUser,
            unitId: 'un',
          );
          final itemInList = ListItem(
            id: 'item-2',
            name: 'Na Lista',
            amount: 1,
            listId: listId,
            createdAt: DateTime.now(),
            createdBy: mockUser,
            unitId: 'un',
          );

          // Simula o retorno do backend
          when(
            () => mockListasRepository.getListItems(any()),
          ).thenAnswer((_) async => [itemInCart, itemInList]);
          when(() => mockListasRepository.getCartItems(any())).thenAnswer(
            (_) async => [
              CartItem(
                id: 'cart-1',
                listItemId: 'item-1',
                user: mockUser,
                addedAt: DateTime.now(),
              ),
            ],
          );
        },
        build: () => listDetailsBloc,
        act: (bloc) => bloc.add(LoadListDetailsEvent()),
        skip: 1, // Pula o estado de Loading
        expect:
            () => [
              // Assert: Verifica o estado final
              isA<ListDetailsLoaded>()
                  .having(
                    (state) => state.items.any((item) => item.id == 'item-1'),
                    'item-1 não deveria estar na lista de compras',
                    isFalse, // Espera que a condição seja falsa
                  )
                  .having(
                    (state) => state.items.any((item) => item.id == 'item-2'),
                    'item-2 deveria estar na lista de compras',
                    isTrue, // Espera que a condição seja verdadeira
                  )
                  .having(
                    (state) => state.cartItems.any(
                      (item) => item.listItemId == 'item-1',
                    ),
                    'item-1 deveria estar no carrinho',
                    isTrue, // Espera que a condição seja verdadeira
                  ),
            ],
      );
    });
  });
}
