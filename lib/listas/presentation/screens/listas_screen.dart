import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/global_cart/presentation/bloc/global_cart_bloc.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter_comprinhas/listas/presentation/components/list_card.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/bloc/listas_bloc.dart';
import 'package:go_router/go_router.dart';

class ListasScreen extends StatelessWidget {
  const ListasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return CustomRefreshIndicator(
      onRefresh: () async {
        context.read<ListasBloc>().add(GetListsEvent());
        context.read<GlobalCartBloc>().add(LoadGlobalCartEvent());
        await Future.delayed(const Duration(seconds: 1));
      },
      builder: (context, child, controller) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            if (!controller.isIdle)
              Positioned(
                top: 35 * controller.value,
                child: SizedBox(
                  height: 30,
                  width: 30,
                  child: CircularProgressIndicator(
                    value:
                        !controller.isLoading
                            ? controller.value.clamp(0, 1)
                            : null,
                  ),
                ),
              ),

            Positioned(
              top: 35 * controller.value,
              child: AnimatedOpacity(
                opacity: controller.isArmed ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  height: 30,
                  width: 30,
                  child: Icon(Icons.check),
                ),
              ),
            ),

            Transform.translate(
              offset: Offset(0, 100 * controller.value),
              child: child,
            ),
          ],
        );
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            sliver: SliverToBoxAdapter(
              child: BlocBuilder<GlobalCartBloc, GlobalCartState>(
                builder: (context, state) {
                  if (state.isLoading) return const LinearProgressIndicator();
                  if (state.error != null) return Text(state.error!);

                  final itemsCount = state.cartItems.length;

                  return Column(
                    children: [
                      TextButton(
                        onPressed: () => context.push('/carrinho'),
                        child: Row(
                          spacing: 8,
                          children: [
                            Icon(Icons.shopping_cart, size: 28),
                            Text("Carrinho", style: textTheme.titleLarge),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "Total: R\$ --,--",
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "$itemsCount itens em seu carrinho",
                        style: textTheme.titleSmall,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Text("Suas Listas", style: textTheme.headlineSmall),
          ),
          BlocBuilder<ListasBloc, ListasState>(
            builder: (context, state) {
              return SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  crossAxisCount: 2,
                ),
                itemCount: state.lists.length,
                itemBuilder: (context, index) {
                  final list = state.lists[index];
                  return ListCard(list: list, units: state.units);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
