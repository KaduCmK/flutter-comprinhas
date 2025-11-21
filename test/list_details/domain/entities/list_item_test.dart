import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/shared/entities/unit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('ListItem', () {
    final testUser = User(
      id: 'user-123',
      appMetadata: {},
      userMetadata: {'name': 'Test User'},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );

    final testUnit = Unit(
      id: 'kg',
      createdAt: DateTime.now(),
      name: 'Kilogram',
      abbreviation: 'kg',
    );

    final testList = ListaCompra(
      id: 'list-1',
      name: 'Test List',
      ownerId: 'user-123',
      createdAt: DateTime.now(),
    );

    final listItem = ListItem(
      id: 'item-1',
      createdAt: DateTime.parse('2025-07-25T12:00:00Z'),
      name: 'Item Teste',
      amount: 5,
      list: testList,
      createdBy: testUser,
      unit: testUnit,
    );

    test('deve criar um ListItem a partir de um Map', () {
      //
      final map = <String, dynamic>{
        'id': 'item-1',
        'created_at': '2025-07-25T12:00:00Z',
        'name': 'Item Teste',
        'amount': 5,
        'list': {
          'id': 'list-1',
          'name': 'Test List',
          'owner_id': 'user-123',
          'created_at': testList.createdAt.toIso8601String(),
          'cart_mode': 'shared',
          'price_forecast_enabled': false,
        },
        'created_by': testUser.toJson(),
        'units': {
          'id': 'kg',
          'created_at': testUnit.createdAt.toIso8601String(),
          'name': 'Kilogram',
          'abbreviation': 'kg',
        },
        'preco_sugerido': null,
      };

      final item = ListItem.fromMap(map);

      expect(item.id, 'item-1');
      expect(item.name, 'Item Teste');
      expect(item.amount, 5);
      expect(item.createdBy.id, 'user-123');
      expect(item.list.id, 'list-1');
      expect(item.unit.id, 'kg');
    });

    test('deve converter um ListItem para um Map', () {
      //
      final result = listItem.toMap();

      final expectedMap = {
        'name': 'Item Teste',
        'amount': 5,
        'list_id': 'list-1',
        'created_by_id': 'user-123',
        'unit_id': 'kg',
        'preco_sugerido': null,
      };

      expect(result, expectedMap);
    });

    test('deve suportar igualdade de valores', () {
      //
      expect(
        listItem,
        equals(
          ListItem(
            id: 'item-1',
            createdAt: DateTime.parse('2025-07-25T12:00:00Z'),
            name: 'Item Teste',
            amount: 5,
            list: testList,
            createdBy: testUser,
            unit: testUnit,
          ),
        ),
      );
    });
  });
}