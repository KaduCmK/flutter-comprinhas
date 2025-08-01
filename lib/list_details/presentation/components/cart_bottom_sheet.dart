import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/cart_item.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_item_card.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details_bloc.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:go_router/go_router.dart';

class CartBottomSheet extends StatelessWidget {
  const CartBottomSheet({super.key});

  // Função auxiliar para buscar os detalhes de um ListItem na lista original
  ListItem? _findListItemDetails(List<ListItem> allItems, CartItem cartItem) {
    return allItems.firstWhereOrNull((item) => item.id == cartItem.listItem.id);
  }

  @override
  Widget build(BuildContext context) {
    // Acessa o BLoC uma vez para evitar múltiplas chamadas
    final listDetailsBloc = context.read<ListDetailsBloc>();

    return BlocConsumer<ListDetailsBloc, ListDetailsState>(
      bloc: listDetailsBloc, // Garante que estamos usando o BLoC correto
      listener: (context, state) {
        if (state.cartItems.isEmpty) {
          context.pop();
        }
      },
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        final cartItems = state.cartItems;
        final allItems = listDetailsBloc.originalItems;
        final isIndividualMode = state.cartMode == CartMode.individual;

        // Agrupa por usuário se for modo individual
        final groupedItems =
            isIndividualMode
                ? groupBy(
                  cartItems,
                  (CartItem item) => item.user.email ?? 'Anônimo',
                )
                : <String, List<CartItem>>{};

        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.2,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    blurRadius: 16,
                    spreadRadius: 4,
                    offset: const Offset(0, -4),
                    color: colorScheme.shadow.withAlpha(30),
                  ),
                ],
                color: colorScheme.surfaceContainerLow,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  // 1. O "puxador"
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Container(
                          height: 5,
                          width: 32,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceDim,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. O Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        spacing: 4,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_basket, size: 32),
                          Text(
                            "Cesta",
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),

                          SegmentedButton(
                            segments: [
                              ButtonSegment(
                                value: CartMode.shared,
                                icon: const Icon(Icons.group),
                              ),
                              ButtonSegment(
                                value: CartMode.individual,
                                icon: const Icon(Icons.person),
                              ),
                            ],
                            selected: {state.cartMode},
                            onSelectionChanged:
                                (mode) => context.read<ListDetailsBloc>().add(
                                  SetCartModeEvent(mode: mode.first),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: Divider(height: 1)),

                  // 3. Lógica de exibição da lista
                  if (isIndividualMode)
                    ...groupedItems.entries.map((entry) {
                      return SliverMainAxisGroup(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                "Itens de: ${entry.key}",
                                style: textTheme.titleMedium,
                              ),
                            ),
                          ),
                          SliverList.builder(
                            itemCount: entry.value.length,
                            itemBuilder: (context, index) {
                              final cartItem = entry.value[index];
                              final itemDetails = _findListItemDetails(
                                allItems,
                                cartItem,
                              );
                              if (itemDetails == null) {
                                return const SizedBox.shrink();
                              }

                              return ListItemCard(
                                item: itemDetails,
                                inCart: true,
                                cartItemId: cartItem.id,
                              );
                            },
                          ),
                          const SliverToBoxAdapter(
                            child: Divider(indent: 16, endIndent: 16),
                          ),
                        ],
                      );
                    })
                  else // Modo Compartilhado
                    SliverList.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final cartItem = cartItems[index];
                        final itemDetails = _findListItemDetails(
                          allItems,
                          cartItem,
                        );
                        if (itemDetails == null) return const SizedBox.shrink();

                        return ListItemCard(
                          item: itemDetails,
                          inCart: true,
                          cartItemId: cartItem.id,
                        );
                      },
                    ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
