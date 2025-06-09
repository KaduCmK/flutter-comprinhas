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

  // NÂO precisa mais de initState pra popular a lista

  void _addItem(ListItem item, int index) {
    // Insere na posição correta pra manter a ordem
    _items.insert(index, item);
    _listKey.currentState?.insertItem(index);
  }

  void _removeItem(ListItem item, int index) {
    // Remove o item e anima a saída dele
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => const SizedBox.shrink(),
    );
    _items.remove(item);
    context.read<ListDetailsBloc>().add(RemoveItemFromListEvent(item.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ListDetailsBloc, ListDetailsState>(
      // Escuta apenas quando a lista for carregada com sucesso
      listenWhen: (previous, current) => current is ListDetailsLoaded,
      listener: (context, state) {
        final newItems = state.items;

        // 1. REMOÇÕES: Itera de trás pra frente pra não bugar os índices
        for (int i = _items.length - 1; i >= 0; i--) {
          final currentItem = _items[i];
          // Se o item da UI não existe na nova lista do BLoC, remove ele
          if (!newItems.contains(currentItem)) {
            _removeItem(currentItem, i);
          }
        }

        // 2. ADIÇÕES: Itera na nova lista do BLoC
        for (int i = 0; i < newItems.length; i++) {
          final newItem = newItems[i];
          // Se o item do BLoC não existe na nossa lista da UI, adiciona ele
          if (!_items.contains(newItem)) {
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
              // O count inicial é 0, o listener vai popular a lista
              initialItemCount: _items.length,
              itemBuilder: (context, index, animation) {
                final item = _items[index];
                return ListItemCard(
                  item: item,
                  animation: animation,
                  onDismiss: (item) {
                    _removeItem(item, index);
                  },
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
