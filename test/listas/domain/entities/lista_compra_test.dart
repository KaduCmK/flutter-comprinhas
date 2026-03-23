import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListaCompra', () {
    final date = DateTime(2024, 7, 25);
    final lista = ListaCompra(
      id: '1',
      name: 'Teste',
      ownerId: 'user-1',
      createdAt: date,
    );

    test('getter createdAtFormatted deve formatar a data para dd/MM/yyyy', () {
      final date = DateTime(2024, 7, 25);
      final lista = ListaCompra(
        id: '1',
        name: 'Teste',
        ownerId: 'user-1',
        createdAt: date,
      );

      final formattedDate = lista.createdAtFormatted;

      expect(formattedDate, '25/07/2024');
    });

    test('deve criar uma ListaCompra a partir de um Map', () {
      final map = {
        'id': '1',
        'name': 'Teste',
        'owner_id': 'user-1',
        'created_at': '2024-07-25T00:00:00.000Z',
        'cart_mode': 'shared',
      };

      final result = ListaCompra.fromMap(map);

      expect(result, isA<ListaCompra>());
      expect(result.id, '1');
      expect(result.name, 'Teste');
      expect(result.ownerId, 'user-1');
      expect(result.createdAtFormatted, '25/07/2024');
    });

    test('deve suportar igualdade de valores', () {
      expect(
        ListaCompra(id: '1', name: 'Teste', ownerId: 'user-1', createdAt: date),
        equals(
          ListaCompra(
            id: '1',
            name: 'Teste',
            ownerId: 'user-1',
            createdAt: date,
          ),
        ),
      );
    });
  });
}
