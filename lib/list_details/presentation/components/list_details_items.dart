// list_details_items.dart
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
  List<ListItem> _displayedItems = [];

  @override
  void initState() {
    super.initState();
    final initialState = BlocProvider.of<ListDetailsBloc>(context).state;
    if (initialState.items.isNotEmpty) {
      _displayedItems = List.from(initialState.items);
    }
  }

  Widget _buildRemovedItemWidget(
    BuildContext context,
    ListItem item,
    Animation<double> animation,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SizeTransition(
        sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ListItemCard(item: item, animation: kAlwaysCompleteAnimation),
      ),
    );
  }

  void _updateListAndAnimate(List<ListItem> newItemsFromBloc) {
    for (int i = _displayedItems.length - 1; i >= 0; i--) {
      final currentItem = _displayedItems[i];
      if (!newItemsFromBloc.any((newItem) => newItem.id == currentItem.id)) {
        final ListItem itemToRemove = _displayedItems.removeAt(
          i,
        ); // Remove from our local list
        _listKey.currentState?.removeItem(
          i,
          (context, animation) =>
              _buildRemovedItemWidget(context, itemToRemove, animation),
          duration: const Duration(
            milliseconds: 200,
          ), // Removal animation duration
        );
      }
    }

    for (
      int targetIndex = 0;
      targetIndex < newItemsFromBloc.length;
      targetIndex++
    ) {
      final newItem = newItemsFromBloc[targetIndex];
      if (targetIndex >= _displayedItems.length) {
        _displayedItems.add(newItem); // Add to our local list
        _listKey.currentState?.insertItem(
          targetIndex,
          duration: const Duration(milliseconds: 300),
        );
      } else if (_displayedItems[targetIndex].id != newItem.id) {
        _displayedItems.insert(
          targetIndex,
          newItem,
        ); // Insert into our local list
        _listKey.currentState?.insertItem(
          targetIndex,
          duration: const Duration(milliseconds: 300),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ListDetailsBloc, ListDetailsState>(
      listener: (context, state) {
        if (state is ListDetailsLoaded) {
          _updateListAndAnimate(List<ListItem>.from(state.items));
        }
      },
      child: CustomScrollView(
        hitTestBehavior: HitTestBehavior.translucent,
        controller: widget.controller,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(top: widget.topCardHeight + 8),
          ),

          DecoratedSliver(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceDim,
              borderRadius: BorderRadius.all(Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.shadow.withValues(alpha: 0.3),
                  spreadRadius: 0.2,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            sliver: SliverAnimatedList(
              key: _listKey,
              initialItemCount: _displayedItems.length,
              itemBuilder:
                  (context, index, animation) => ListItemCard(
                    item: _displayedItems[index],
                    animation: animation,
                  ),
            ),
          ),

          SliverPadding(padding: const EdgeInsets.only(bottom: 150)),
        ],
      ),
    );
  }
}
