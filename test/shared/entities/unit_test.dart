import 'package:flutter_comprinhas/shared/entities/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Unit', () {
    final unit = Unit(
      id: '1',
      createdAt: DateTime(2024, 7, 25),
      name: 'Kilogram',
      abbreviation: 'kg',
      category: 'Mass',
      description: 'A unit of mass',
    );

    test('deve criar uma Unit a partir de um map', () {
      final map = {
        'id': '1',
        'created_at': '2024-07-25T00:00:00.000',
        'name': 'Kilogram',
        'abbreviation': 'kg',
        'category': 'Mass',
        'description': 'A unit of mass',
      };

      final result = Unit.fromMap(map);

      expect(result, isA<Unit>());
      expect(result.id, '1');
      expect(result.name, 'Kilogram');
      expect(result.abbreviation, 'kg');
    });

    test('deve converter uma Unit para um map', () {
      final result = unit.toMap();

      final expectedMap = {
        'id': '1',
        'createdAt': DateTime(2024, 7, 25).millisecondsSinceEpoch,
        'name': 'Kilogram',
        'abbreviation': 'kg',
        'category': 'Mass',
        'description': 'A unit of mass',
      };

      expect(result, expectedMap);
    });

    test('deve suportar igualdade de valores', () {
      expect(
        Unit(
          id: '1',
          createdAt: DateTime(2024, 7, 25),
          name: 'Kilogram',
          abbreviation: 'kg',
        ),
        equals(
          Unit(
            id: '1',
            createdAt: DateTime(2024, 7, 25),
            name: 'Kilogram',
            abbreviation: 'kg',
          ),
        ),
      );
    });

    test('copyWith deve criar uma copia com valores atualizados', () {
      final copiedUnit = unit.copyWith(name: 'Gram', abbreviation: 'g');

      expect(copiedUnit.name, 'Gram');
      expect(copiedUnit.abbreviation, 'g');
      expect(copiedUnit.id, unit.id);
    });
  });
}