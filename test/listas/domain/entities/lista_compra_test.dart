import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListaCompra', () {
    test('getter createdAt deve formatar a data para dd/MM/yyyy', () {
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
  });
}