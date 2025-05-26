import 'package:flutter/material.dart';

class ListasScreen extends StatelessWidget {
  const ListasScreen({super.key});

  final List<Map<String, String>> _mockListas = const [
    {'id': '1', 'nome': 'Supermercado Semanal'},
    {'id': '2', 'nome': 'Feira Orgânica'},
    {'id': '3', 'nome': 'Farmácia'},
    {'id': '4', 'nome': 'Material de Construção'},
    {'id': '5', 'nome': 'Presentes Aniversário'},
    {'id': '6', 'nome': 'Compras Online'},
    {'id': '7', 'nome': 'Viagem Praia'},
    {'id': '8', 'nome': 'Livros para Ler'},
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Text(
            "Suas Listas",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            crossAxisCount: 2,
          ),
          itemCount: _mockListas.length,
          itemBuilder: (context, index) {
            final lista = _mockListas[index];
            return Card(
              elevation: 2,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lista['nome']!,
                        style: Theme.of(context).textTheme.titleMedium!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),

                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
