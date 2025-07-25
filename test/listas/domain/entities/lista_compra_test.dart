import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListaCompra', () {
    final date = DateTime(2024, 7, 25);
    final lista = ListaCompra(id: '1', name: 'Teste', createdAt: date);

    test('getter createdAt deve formatar a data para dd/MM/yyyy', () { //
      // 1. ARRANGE
      // criar os ojetos e variaveis necessarios pro teste
      final date = DateTime(2024, 7, 25);
      final lista = ListaCompra(id: '1', name: 'Teste', createdAt: date);

      // 2. ACT
      // executa a funcao ou metodo a ser testado
      final formattedDate = lista.createdAt;

      // 3. ASSERT
      // verifica se o resultado é o esperado
      expect(formattedDate, '25/07/2024');
    });

    test('deve criar uma ListaCompra a partir de um Map', () { //
      final map = {
        'id': '1',
        'name': 'Teste',
        'created_at': '2024-07-25T00:00:00.000Z',
      };

      final result = ListaCompra.fromMap(map);

      expect(result, isA<ListaCompra>());
      expect(result.id, '1');
      expect(result.name, 'Teste');
      expect(result.createdAt, '25/07/2024');
    });

    test('deve suportar igualdade de valores', () { //
      expect(
        ListaCompra(id: '1', name: 'Teste', createdAt: date),
        equals(ListaCompra(id: '1', name: 'Teste', createdAt: date)),
      );
    });
  });
}