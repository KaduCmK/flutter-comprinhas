import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/core/components/split_button.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/cart_bottom_sheet.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_details_app_bar.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_details_items.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details_bloc.dart';

class ListDetailsScreen extends StatefulWidget {
  const ListDetailsScreen({super.key});

  @override
  State<ListDetailsScreen> createState() => _ListDetailsScreenState();
}

class _ListDetailsScreenState extends State<ListDetailsScreen> {
  static const double topCardHeight = 150;

  late final ScrollController _controller;
  double _topCardParallaxOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScroll);
    _controller.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_controller.hasClients) {
      final offset = _controller.offset;
      setState(() {
        _topCardParallaxOffset = -offset * 0.20;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final listDetailsBloc = context.read<ListDetailsBloc>();

    return BlocBuilder<ListDetailsBloc, ListDetailsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Stack(
            children: [
              Positioned(
                top: statusBarHeight + _topCardParallaxOffset,
                left: 0,
                right: 0,
                child: ListDetailsAppBar(topCardHeight: topCardHeight),
              ),
              Positioned(
                top: topCardHeight + statusBarHeight + 2,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child:
                      state is ListDetailsLoading
                          ? const LinearProgressIndicator()
                          : const SizedBox(height: 4),
                ),
              ),
              ListDetailsItems(
                controller: _controller,
                topCardHeight: topCardHeight + statusBarHeight,
              ),

              Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    final curvedAnimation = CurvedAnimation(
                      parent: animation,
                      curve: Curves.ease,
                    );
                    final slideAnimation = Tween<Offset>(
                      begin: const Offset(0, 2),
                      end: Offset.zero,
                    ).animate(curvedAnimation);
                    return SlideTransition(
                      position: slideAnimation,
                      child: child,
                    );
                  },
                  child:
                      (state.cartItems.isNotEmpty)
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SplitButton(
                                itemCount: state.cartItems.length,
                                onPrimaryAction:
                                    () => showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      useSafeArea: true,
                                      backgroundColor: Colors.transparent,
                                      builder:
                                          (_) => BlocProvider.value(
                                            value:
                                                listDetailsBloc, // Passando o BLoC
                                            child: const CartBottomSheet(),
                                          ),
                                    ),
                                onSecondaryAction:
                                    () =>
                                        state is ListDetailsLoading
                                            ? null
                                            : context
                                                .read<ListDetailsBloc>()
                                                .add(ConfirmPurchaseEvent()),
                              ),
                            ],
                          )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
