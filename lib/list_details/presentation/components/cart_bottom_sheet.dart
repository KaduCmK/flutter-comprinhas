import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/cart_item.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_item_card.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/cart/cart_bloc.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:go_router/go_router.dart';

class CartBottomSheet extends StatelessWidget {
  const CartBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CartBloc, CartState>(
      listener: (context, state) {
        if (!state.isLoading && state.cartItems.isEmpty) {
          context.pop();
        }
      },
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        final cartItems = state.cartItems;
        final isIndividualMode = state.cartMode == CartMode.individual;

        // Agrupa por usuário se for modo individual
        final groupedItems = isIndividualMode
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_basket, size: 32),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Cesta",
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${cartItems.length} ite${cartItems.length == 1 ? 'm' : 'ns'}",
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const Spacer(),
                          SegmentedButton(
                            segments: const [
                              ButtonSegment(
                                value: CartMode.shared,
                                icon: Icon(Icons.group),
                              ),
                              ButtonSegment(
                                value: CartMode.individual,
                                icon: Icon(Icons.person),
                              ),
                            ],
                            selected: {state.cartMode},
                            onSelectionChanged: (mode) => context
                                .read<CartBloc>()
                                .add(SetCartMode(mode.first)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 32),
                    sliver: SliverToBoxAdapter(
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.read<CartBloc>().add(ConfirmPurchase()),
                        icon: const Icon(Icons.payments),
                        label: const Text("Finalizar Compras"),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: Divider(height: 1)),

                  // 3. Lógica de exibição da lista
                  if (state.isLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (isIndividualMode)
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
                              return ListItemCard(
                                item: cartItem.listItem,
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
                        return ListItemCard(
                          item: cartItem.listItem,
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