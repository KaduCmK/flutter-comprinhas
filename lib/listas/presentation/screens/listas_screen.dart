import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/listas/presentation/components/list_card.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/bloc/listas_bloc.dart';

class ListasScreen extends StatelessWidget {
  const ListasScreen({super.key});

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
        BlocBuilder<ListasBloc, ListasState>(
          builder: (context, state) {
            return SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                crossAxisCount: 2,
              ),
              itemCount: state.lists.length,
              itemBuilder: (context, index) {
                final list = state.lists[index];
                return ListCard(list: list, units: state.units);
              },
            );
          },
        ),
      ],
    );
  }
}
