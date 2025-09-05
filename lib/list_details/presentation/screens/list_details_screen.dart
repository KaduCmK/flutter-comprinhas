// in list_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/core/components/split_button.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/cart_bottom_sheet.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_details_app_bar.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_details_items.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/cart/cart_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details/list_details_bloc.dart';

class ListDetailsScreen extends StatefulWidget {
  const ListDetailsScreen({super.key});

  @override
  State<ListDetailsScreen> createState() => _ListDetailsScreenState();
}

class _ListDetailsScreenState extends State<ListDetailsScreen> {
  // A _listKey foi removida pois não é mais necessária com a simplificação
  // final _listKey = GlobalKey<SliverAnimatedListState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          return AnimatedOpacity(
            opacity: state.cartItems.isEmpty ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
            child: AnimatedSlide(
              offset:
                  state.cartItems.isEmpty ? const Offset(0, 1) : Offset.zero,
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
              child: SplitButton(
                itemCount: state.cartItems.length,
                onPrimaryAction: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder:
                        (_) => BlocProvider.value(
                          value: context.read<CartBloc>(),
                          child: const CartBottomSheet(),
                        ),
                  );
                },
                onSecondaryAction:
                    () => context.read<CartBloc>().add(ConfirmPurchase()),
              ),
            ),
          );
        },
      ),
      body: BlocConsumer<ListDetailsBloc, ListDetailsState>(
        listenWhen:
            (previous, current) =>
                previous.list?.priceForecastEnabled != null &&
                previous.list?.priceForecastEnabled !=
                    current.list?.priceForecastEnabled,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'A estimativa de preço foi ${state.list?.priceForecastEnabled ?? false ? 'ativada. Novos itens terão um preço estimado adicionado a eles' : 'desativada. Novos itens não receberão a previsão de preço'}.',
              ),
            ),
          );
        },
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              const SliverAppBar(
                snap: true,
                floating: true,
                automaticallyImplyLeading: true,
                expandedHeight: 160,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: ListDetailsAppBar(),
                ),
              ),

              const ListDetailsItems(),
            ],
          );
        },
      ),
    );
  }
}
