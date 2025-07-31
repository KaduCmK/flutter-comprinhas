import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_item_card.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details_bloc.dart';

class ListDetailsItems extends StatefulWidget {
  final ScrollController controller;
  final double topCardHeight;

  const ListDetailsItems({
    super.key,
    required this.controller,
    required this.topCardHeight,
  });

  @override
  State<ListDetailsItems> createState() => _ListDetailsItemsState();
}

class _ListDetailsItemsState extends State<ListDetailsItems> {
  final _listKey = GlobalKey<SliverAnimatedListState>();
  // A lista local que controla a animação
  final List<ListItem> _items = [];

  void _addItem(ListItem item, int index) {
    // Insere na posição correta pra manter a ordem
    _items.insert(index, item);
    _listKey.currentState?.insertItem(index);
  }

  // Esta função SÓ remove o item da UI, sem disparar eventos.
  // Será usada pelo BlocListener quando um item for para o carrinho.
  void _animateRemoval(ListItem item, int index) {
    _listKey.currentState?.removeItem(
      index,
      // Usamos um SizedBox.shrink() porque a remoção já é gerenciada pelo estado
      (context, animation) => const SizedBox.shrink(),
    );
    _items.remove(item);
  }

  // Esta função DELETA o item do banco de dados.
  // Será usada pelo onDismiss (swipe) do ListItemCard.
  void _deleteItem(ListItem item, int index) {
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => const SizedBox.shrink(),
    );
    _items.remove(item);
    // Dispara o evento para remover o item do banco de dados
    context.read<ListDetailsBloc>().add(RemoveItemFromListEvent(item.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ListDetailsBloc, ListDetailsState>(
      listenWhen: (previous, current) => current is ListDetailsLoaded,
      listener: (context, state) {
        final newItems = state.items;
        
        for (int i = _items.length - 1; i >= 0; i--) {
          final currentItem = _items[i];
          // Se o item da UI não existe mais na lista do BLoC...
          if (!newItems.any((item) => item.id == currentItem.id)) {
            // ...chame a função que SÓ anima, sem deletar.
            _animateRemoval(currentItem, i);
          }
        }

        // A lógica de adição permanece a mesma
        for (int i = 0; i < newItems.length; i++) {
          final newItem = newItems[i];
          if (!_items.any((item) => item.id == newItem.id)) {
            _addItem(newItem, i);
          }
        }
      },
      child: CustomScrollView(
        hitTestBehavior: HitTestBehavior.translucent,
        controller: widget.controller,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(top: widget.topCardHeight + 10),
          ),
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
