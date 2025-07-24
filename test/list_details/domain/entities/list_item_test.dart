import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
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

    test('deve criar um ListItem a partir de um Map', () {
      final map = <String, dynamic>{
        'id': 'item-1',
        'created_at': '2025-07-25T12:00:00Z',
        'name': 'Item Teste',
        'amount': 5,
        'list_id': 'list-1',
        'created_by': testUser.toJson(),
        'unitId': 'kg',
      };

      final item = ListItem.fromMap(map);

      expect(item.id, 'item-1');
      expect(item.name, 'Item Teste');
      expect(item.amount, 5);
      expect(item.createdBy.id, 'user-123');
    });
  });
}
