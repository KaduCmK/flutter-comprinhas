import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/cart_item.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/cart/cart_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details/list_details_bloc.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/shared/entities/unit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../mocks.dart';

class MockUser extends Mock implements User {}

void main() {
  setUpAll(() {
    registerFallbackValue(CartMode.shared);
    registerFallbackValue(FakeRealtimeChannel());
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(
      PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'list_id',
        value: 'list-1',
      ),
    );
  });

  group('ListDetailsBloc', () {
    late MockListasRepository mockListasRepository;
    late ListDetailsBloc listDetailsBloc;
    late CartBloc cartBloc;
    late ListaCompra mockList;
    late List<ListItem> mockItems;
    late User mockUser;
    late MockSupabaseClient mockSupabaseClient;
    late MockGotrueClient mockGotrueClient;
    late Unit mockUnit;

    const listId = 'list-1';

    setUp(() {
      mockListasRepository = MockListasRepository();
      mockUser = MockUser();
      mockSupabaseClient = MockSupabaseClient();
      mockGotrueClient = MockGotrueClient();

      when(() => mockUser.id).thenReturn('user-123');
      when(() => mockUser.toJson()).thenReturn({
        'id': 'user-123',
        'email': 'test@test.com',
        'app_metadata': {},
        'user_metadata': {},
        'aud': 'aud',
        'created_at': DateTime.now().toIso8601String(),
      });

      final mockChannel = MockRealtimeChannel();
      when(
        () => mockChannel.onPostgresChanges(
          event: any(named: 'event'),
          schema: any(named: 'schema'),
          table: any(named: 'table'),
          filter: any(named: 'filter'),
          callback: any(named: 'callback'),
        ),
      ).thenReturn(mockChannel);
      when(() => mockChannel.subscribe()).thenReturn(mockChannel);

      when(() => mockSupabaseClient.auth).thenReturn(mockGotrueClient);
      when(() => mockGotrueClient.currentUser).thenReturn(mockUser);
      when(() => mockSupabaseClient.channel(any())).thenReturn(mockChannel);
      when(
        () => mockSupabaseClient.removeChannel(any()),
      ).thenAnswer((_) async => 'OK');

      mockList = ListaCompra(
        id: listId,
        name: 'Test List',
        ownerId: 'user-123',
        createdAt: DateTime.now(),
        cartMode: CartMode.shared,
      );

      mockUnit = Unit(
        id: 'un',
        name: 'Unidade',
        abbreviation: 'un',
        createdAt: DateTime.now(),
      );

      mockItems = [
        ListItem(
          id: 'item-1',
          name: 'Item 1',
          amount: 1,
          list: mockList,
          createdAt: DateTime.now(),
          createdBy: mockUser,
          unit: mockUnit,
        ),
        ListItem(
          id: 'item-2',
          name: 'Item 2',
          amount: 2,
          list: mockList,
          createdAt: DateTime.now(),
          createdBy: mockUser,
          unit: mockUnit,
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

      cartBloc = CartBloc(
        client: mockSupabaseClient,
        repository: mockListasRepository,
        listId: listId,
      );

      listDetailsBloc = ListDetailsBloc(
        client: mockSupabaseClient,
        repository: mockListasRepository,
        listId: listId,
        cartBloc: cartBloc,
      );
    });

    test('Estado inicial deve ser ListDetailsState.initial()', () {
      expect(listDetailsBloc.state, ListDetailsState.initial());
    });

    blocTest<ListDetailsBloc, ListDetailsState>(
      'deve emitir itens carregados',
      build: () => listDetailsBloc,
      act: (bloc) => bloc.add(LoadListDetails()),
      expect:
          () => [
            isA<ListDetailsState>().having(
              (s) => s.isLoading,
              'isLoading',
              true,
            ),
            isA<ListDetailsState>()
                .having((s) => s.isLoading, 'isLoading', false)
                .having((s) => s.list, 'list', mockList)
                .having((s) => s.items, 'items vazios antes do filtro final', isEmpty),
            isA<ListDetailsState>()
                .having((s) => s.isLoading, 'isLoading', false)
                .having((s) => s.list, 'list', mockList)
                .having((s) => s.items.length, 'items carregados', 2),
          ],
      verify: (_) {
        verify(() => mockListasRepository.getListById(listId)).called(1);
        verify(() => mockListasRepository.getListItems(listId)).called(1);
      },
    );

    // bateria de testes para funcionalidade do carrinho deve ser feita no cart_bloc_test.dart
    // aqui vamos testar a integração do list_details com o cart_bloc
    group('Integração com Carrinho', () {
      blocTest<ListDetailsBloc, ListDetailsState>(
        'deve filtrar itens da lista quando eles estão no carrinho',
        setUp: () {
          final itemInCart = ListItem(
            id: 'item-1',
            name: 'No Carrinho',
            amount: 1,
            list: mockList,
            createdAt: DateTime.now(),
            createdBy: mockUser,
            unit: mockUnit,
          );
          final itemInList = ListItem(
            id: 'item-2',
            name: 'Na Lista',
            amount: 1,
            list: mockList,
            createdAt: DateTime.now(),
            createdBy: mockUser,
            unit: mockUnit,
          );

          when(
            () => mockListasRepository.getListItems(any()),
          ).thenAnswer((_) async => [itemInCart, itemInList]);

          // Simula que o CartBloc tem o item-1 no carrinho
          when(() => mockListasRepository.getCartItems(any())).thenAnswer(
            (_) async => [
              CartItem(
                id: 'cart-1',
                listItem: itemInCart,
                user: mockUser,
                addedAt: DateTime.now(),
              ),
            ],
          );
        },
        build: () => listDetailsBloc,
        act: (bloc) {
          cartBloc.add(LoadCart());
          bloc.add(LoadListDetails());
        },
        skip: 2, // Pula carregamento inicial do cart e loading do details
        expect:
            () => [
              isA<ListDetailsState>()
                  .having(
                    (s) => s.items.length,
                    'deve ter apenas 1 item (o que não está no carrinho)',
                    1,
                  )
                  .having(
                    (s) => s.items.first.id,
                    'o item deve ser o item-2',
                    'item-2',
                  ),
            ],
      );
    });
  });
}
