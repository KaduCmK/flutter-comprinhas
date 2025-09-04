import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_item_card.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details_bloc.dart';

class ListDetailsItems extends StatefulWidget {

  const ListDetailsItems({super.key});

  @override
  State<ListDetailsItems> createState() => _ListDetailsItemsState();
}

class _ListDetailsItemsState extends State<ListDetailsItems> {
  final _listKey = GlobalKey<SliverAnimatedListState>();
  final List<ListItem> _items = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inicializa a lista de itens com o estado atual do BLoC
    final state = context.watch<ListDetailsBloc>().state;
    if (state is ListDetailsLoaded) {
      _items.clear();
      _items.addAll(state.items);
    }
  }

  void _addItem(ListItem item, int index) {
    _items.insert(index, item);
    _listKey.currentState?.insertItem(index);
  }

  void _animateRemoval(ListItem item, int index) {
    _listKey.currentState?.removeItem(
      index,
      // Usamos o próprio card para uma animação de saída suave
      (context, animation) => ListItemCard(item: item, animation: animation),
    );
    _items.remove(item);
  }

  void _deleteItem(ListItem item, int index) {
    final removedItem = _items.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) =>
          ListItemCard(item: removedItem, animation: animation),
    );
    context.read<ListDetailsBloc>().add(RemoveItemFromListEvent(item.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ListDetailsBloc, ListDetailsState>(
      listenWhen:
          (previous, current) =>
              previous is ListDetailsLoading ||
              (previous is ListDetailsLoaded &&
                  current is ListDetailsLoaded &&
                  previous.items != current.items),
      listener: (context, state) {
        if (state is! ListDetailsLoaded) return;

        final newItems = state.items;

        // Lógica de Sincronização (Diffing)
        // 1. Remove os itens que não existem mais
        for (int i = _items.length - 1; i >= 0; i--) {
          final currentItem = _items[i];
          if (!newItems.any((item) => item.id == currentItem.id)) {
            _animateRemoval(currentItem, i);
          }
        }

        // 2. Adiciona ou move os itens para suas posições corretas
        for (int i = 0; i < newItems.length; i++) {
          final newItem = newItems[i];
          if (i >= _items.length || _items[i].id != newItem.id) {
            // Se o item já existe na lista, mas em outro lugar, é uma movimentação
            final oldIndex = _items.indexWhere((item) => item.id == newItem.id);
            if (oldIndex != -1) {
              final itemToMove = _items.removeAt(oldIndex);
              // Anima a remoção da posição antiga (sem widget visível)
              _listKey.currentState?.removeItem(
                oldIndex,
                (context, animation) => const SizedBox.shrink(),
                duration: const Duration(milliseconds: 150),
              );
              // Anima a inserção na nova posição
              _items.insert(i, itemToMove);
              _listKey.currentState?.insertItem(
                i,
                duration: const Duration(milliseconds: 150),
              );
            } else {
              // Se é um item completamente novo, apenas insere
              _addItem(newItem, i);
            }
          }
        }
      },
      child: CustomScrollView(
        hitTestBehavior: HitTestBehavior.translucent,
        slivers: [
          SliverPadding(padding: EdgeInsets.only(top: 10)),
          DecoratedSliver(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceDim,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
            ),
            sliver: SliverAnimatedList(
              key: _listKey,
              initialItemCount: _items.length,
              itemBuilder: (context, index, animation) {
                final item = _items[index];
                return ListItemCard(
                  item: item,
                  animation: animation,
                  onDismiss: (item) {
                    _deleteItem(item, index);
                  },
                  inCart: false,
                );
              },
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 150)),
        ],
      ),
    );
  }
}
