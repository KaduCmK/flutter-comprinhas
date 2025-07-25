import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/bloc/listas_bloc.dart';
import 'package:flutter_comprinhas/shared/entities/unit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../mocks.dart';

void main() {
  group('ListasBloc', () {
    late MockListasRepository mockListasRepository;

    final mockListas = [
      ListaCompra(id: '1', name: 'Lista 1', createdAt: DateTime.now()),
      ListaCompra(id: '2', name: 'Lista 2', createdAt: DateTime.now()),
    ];
    final mockUnits = [
      Unit(id: '1', name: 'kg', abbreviation: 'kg', createdAt: DateTime.now())
    ];

    setUp(() {
      mockListasRepository = MockListasRepository();
      when(() => mockListasRepository.getUserLists())
          .thenAnswer((_) async => mockListas);
      when(() => mockListasRepository.getUnits())
          .thenAnswer((_) async => mockUnits);
      when(() => mockListasRepository.createList(any()))
          .thenAnswer((_) async {});
    });

    test('o estado inicial deve ser ListasInitial', () {
      expect(ListasBloc(repository: mockListasRepository).state, isA<ListasInitial>());
    });

    blocTest<ListasBloc, ListasState>(
      'deve emitir [ListasLoading, ListasLoaded] quando GetListsEvent é adicionado.',
      build: () => ListasBloc(repository: mockListasRepository),
      act: (bloc) => bloc.add(GetListsEvent()),
      expect: () => [
        isA<ListasLoading>(),
        isA<ListasLoaded>(),
      ],
      verify: (_) {
        verify(() => mockListasRepository.getUserLists()).called(1);
        verify(() => mockListasRepository.getUnits()).called(1);
      },
    );

    blocTest<ListasBloc, ListasState>(
      'deve emitir [ListasLoading, ListasLoaded] quando CreateListEvent é adicionado.',
      build: () => ListasBloc(repository: mockListasRepository),
      act: (bloc) => bloc.add(const CreateListEvent('Nova Lista')),
      expect: () => [
        isA<ListasLoading>(),
        isA<ListasLoaded>(),
      ],
      verify: (_) {
        verify(() => mockListasRepository.createList('Nova Lista')).called(1);
        verify(() => mockListasRepository.getUserLists()).called(1);
      },
    );

    blocTest<ListasBloc, ListasState>(
      'deve emitir [ListasLoading, ListasError] quando o repositório lança um erro.',
      build: () {
        when(() => mockListasRepository.getUserLists()).thenThrow(Exception('Erro de Teste'));
        return ListasBloc(repository: mockListasRepository);
      },
      act: (bloc) => bloc.add(GetListsEvent()),
      expect: () => [
        isA<ListasLoading>(),
        isA<ListasError>(),
      ],
    );
  });
}