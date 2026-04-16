import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/cart/cart_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../mocks.dart';

class MockUser extends Mock implements User {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRealtimeChannel());
    registerFallbackValue(PostgresChangeEvent.all);
  });

  group('CartBloc realtime', () {
    late MockListasRepository mockListasRepository;
    late MockSupabaseClient mockSupabaseClient;
    late MockGotrueClient mockGotrueClient;
    late MockRealtimeChannel mockChannel;
    late MockUser mockUser;

    const listId = 'list-1';

    setUp(() {
      mockListasRepository = MockListasRepository();
      mockSupabaseClient = MockSupabaseClient();
      mockGotrueClient = MockGotrueClient();
      mockChannel = MockRealtimeChannel();
      mockUser = MockUser();

      when(() => mockUser.id).thenReturn('user-123');
      when(() => mockSupabaseClient.auth).thenReturn(mockGotrueClient);
      when(() => mockGotrueClient.currentUser).thenReturn(mockUser);
      when(() => mockSupabaseClient.channel(any())).thenReturn(mockChannel);
      when(
        () => mockChannel.onPostgresChanges(
          event: any(named: 'event'),
          schema: any(named: 'schema'),
          table: any(named: 'table'),
          callback: any(named: 'callback'),
        ),
      ).thenReturn(mockChannel);
      when(() => mockChannel.subscribe(any())).thenReturn(mockChannel);
      when(
        () => mockSupabaseClient.removeChannel(any()),
      ).thenAnswer((_) async => 'ok');
      when(
        () => mockListasRepository.getCartItems(listId),
      ).thenAnswer((_) async => []);
    });

    blocTest<CartBloc, CartState>(
      'recarrega o carrinho quando o evento do realtime pertence a lista atual',
      build:
          () => CartBloc(
            repository: mockListasRepository,
            client: mockSupabaseClient,
            listId: listId,
            isCurrentListItem: (_) async => true,
          ),
      act: (bloc) async {
        final callback =
            verify(
                  () => mockChannel.onPostgresChanges(
                    event: any(named: 'event'),
                    schema: any(named: 'schema'),
                    table: any(named: 'table'),
                    callback: captureAny(named: 'callback'),
                  ),
                ).captured.single
                as Future<void> Function(PostgresChangePayload);

        await callback(
          PostgresChangePayload(
            schema: 'public',
            table: 'cart_items',
            commitTimestamp: DateTime.now(),
            eventType: PostgresChangeEvent.insert,
            newRecord: {'list_item_id': 'item-1'},
            oldRecord: const {},
            errors: null,
          ),
        );
      },
      expect:
          () => [
            isA<CartState>().having(
              (state) => state.isLoading,
              'isLoading',
              true,
            ),
            isA<CartState>().having(
              (state) => state.isLoading,
              'isLoading',
              false,
            ),
          ],
      verify: (_) {
        verify(() => mockListasRepository.getCartItems(listId)).called(1);
      },
    );

    blocTest<CartBloc, CartState>(
      'ignora eventos de outras listas no realtime',
      build:
          () => CartBloc(
            repository: mockListasRepository,
            client: mockSupabaseClient,
            listId: listId,
            isCurrentListItem: (_) async => false,
          ),
      act: (bloc) async {
        final callback =
            verify(
                  () => mockChannel.onPostgresChanges(
                    event: any(named: 'event'),
                    schema: any(named: 'schema'),
                    table: any(named: 'table'),
                    callback: captureAny(named: 'callback'),
                  ),
                ).captured.single
                as Future<void> Function(PostgresChangePayload);

        await callback(
          PostgresChangePayload(
            schema: 'public',
            table: 'cart_items',
            commitTimestamp: DateTime.now(),
            eventType: PostgresChangeEvent.insert,
            newRecord: {'list_item_id': 'item-outra-lista'},
            oldRecord: const {},
            errors: null,
          ),
        );

        await Future<void>.delayed(Duration.zero);
      },
      expect: () => <CartState>[],
      verify: (_) {
        verifyNever(() => mockListasRepository.getCartItems(listId));
      },
    );
  });
}
