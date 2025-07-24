
import 'package:flutter_comprinhas/listas/data/listas_repository_impl.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../mocks.dart';

void main() {
  // Declara as variaveis que vamos usar nos testes
  late ListasRepositoryImpl repository;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockUser mockUser;
  late MockPostgrestClient mockPostgrestClient;

  // 'setUp' é executado antes de cada teste. Bom para inicializar o ambiente
  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockUser = MockUser();
    mockPostgrestClient = MockPostgrestClient();

    // cria uma instancia falsa do Supabase.instance.client
    // garante que o repository use o mock
    repository = ListasRepositoryImpl(client: mockSupabaseClient);

    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('user-id-123');

    group('getUserLists', () {
      test('deve retornar uma lista de ListaCompra', () async {
        final mockData = [
          {
            'id': '1',
            'name': 'Compras da Semana',
            'created_at': '2025-07-24T10:00:00.000Z',
            'list_members': [],
          },
        ];

        final result = await repository.getUserLists();

        expect(result, isA<List<ListaCompra>>());
        expect(result.length, 1);
        expect(result[0].name, 'Compras da Semana');
      });
    });
  });
}
