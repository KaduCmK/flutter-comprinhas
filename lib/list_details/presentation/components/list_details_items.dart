// in list_details_items.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_item_card.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details/list_details_bloc.dart';

class ListDetailsItems extends StatelessWidget {
  const ListDetailsItems({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<ListDetailsBloc>().state.items;

    return SliverMainAxisGroup(
      slivers: [
        const SliverPadding(padding: EdgeInsets.only(top: 10)),
        DecoratedSliver(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceDim,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
          ),
          sliver: SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListItemCard(
                item: item,
                inCart: false,
                onDelete: () {
                  context.read<ListDetailsBloc>().add(
                    RemoveItemFromList(item.id),
                  );
                },
                onEdit: () {
                  // TODO: Implementar lógica de edição
                  print("Editar item: ${item.name}");
                },
              );
            },
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }
}
