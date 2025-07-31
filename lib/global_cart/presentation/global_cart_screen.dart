import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/global_cart/presentation/bloc/global_cart_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_item_card.dart';

class GlobalCartScreen extends StatelessWidget {
  const GlobalCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Carrinho Global")),
      body: BlocBuilder<GlobalCartBloc, GlobalCartState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(child: Text(state.error!));
          }

          final groupedItems = groupBy(
            state.cartItems,
            (item) => item.listItem.list.name,
          );
          final totalItems = state.cartItems.length;
          final listNames = groupedItems.keys.toList();

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Text(
                        "$totalItems itens",
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text("R\$ --,--", style: textTheme.displayMedium),
                      Text("(Valor aproximado)", style: textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),

              SliverList.builder(
                itemCount: listNames.length,
                itemBuilder: (context, index) {
                  final listName = listNames[index];
                  final itemsInList = groupedItems[listName]!;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        ...itemsInList.map(
                          (cartItem) => ListItemCard(item: cartItem.listItem, inCart: true,),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
