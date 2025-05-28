// list_details_items.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_item_card.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details_bloc.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ListDetailsItems extends StatelessWidget {
  final ScrollController controller;
  final double topCardHeight;
  const ListDetailsItems({
    super.key,
    required this.controller,
    required this.topCardHeight,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListDetailsBloc, ListDetailsState>(
      builder: (context, state) {
        return CustomScrollView(
          hitTestBehavior: HitTestBehavior.translucent,
          controller: controller,
          slivers: [
            SliverPadding(padding: EdgeInsets.only(top: topCardHeight + 8)),

            DecoratedSliver(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceDim,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              sliver: MultiSliver(
                children: [
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                      child: Text(
                        "Itens:",
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  SliverList.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];

                      return ListItemCard(item);
                    },
                  ),

                  SliverPadding(padding: const EdgeInsets.only(bottom: 160))
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
