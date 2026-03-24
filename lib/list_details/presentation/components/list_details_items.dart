import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_item_card.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details/list_details_bloc.dart';

class ListDetailsItems extends StatefulWidget {
  const ListDetailsItems({super.key});

  @override
  State<ListDetailsItems> createState() => _ListDetailsItemsState();
}

class _ListDetailsItemsState extends State<ListDetailsItems> {
  final GlobalKey<SliverAnimatedListState> _listKey = GlobalKey<SliverAnimatedListState>();
  final List<ListItem> _items = [];

  @override
  void initState() {
    super.initState();
    // Inicializa com os itens atuais do Bloc
    final currentItems = context.read<ListDetailsBloc>().state.items;
    _items.addAll(currentItems);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ListDetailsBloc, ListDetailsState>(
      listenWhen: (previous, current) => previous.items != current.items,
      listener: (context, state) {
        _updateItems(state.items);
      },
      child: SliverMainAxisGroup(
        slivers: [
          const SliverPadding(padding: EdgeInsets.only(top: 10)),
          DecoratedSliver(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceDim,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
            ),
            sliver: SliverAnimatedList(
              key: _listKey,
              initialItemCount: _items.length,
              itemBuilder: (context, index, animation) {
                // Prevenção contra índices fora de alcance durante animações rápidas
                if (index >= _items.length) return const SizedBox.shrink();
                final item = _items[index];
                return _buildItem(item, animation);
              },
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildItem(ListItem item, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: ListItemCard(
          item: item,
          inCart: false,
          onDelete: () {
            context.read<ListDetailsBloc>().add(
              RemoveItemFromList(item.id),
            );
          },
          onEdit: () {
            // TODO: Implementar lógica de edição
          },
        ),
      ),
    );
  }

  void _updateItems(List<ListItem> newItems) {
    // 1. Detectar Remoções
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (!newItems.any((ni) => ni.id == item.id)) {
        final removedItem = _items.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildItem(removedItem, animation),
          duration: const Duration(milliseconds: 300),
        );
        i--;
      }
    }

    // 2. Detectar Inserções
    for (int i = 0; i < newItems.length; i++) {
      final newItem = newItems[i];
      if (!_items.any((oi) => oi.id == newItem.id)) {
        _items.insert(i, newItem);
        _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 500));
      }
    }

    // 3. Atualizar estados internos (caso o conteúdo do item tenha mudado mas o ID não)
    setState(() {
      for (int i = 0; i < newItems.length; i++) {
        if (i < _items.length) {
          _items[i] = newItems[i];
        }
      }
    });
  }
}
