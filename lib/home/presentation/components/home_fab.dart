import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/bloc/listas_bloc.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:go_router/go_router.dart';

class HomeFab extends StatelessWidget {
  final int selectedIndex;
  
  const HomeFab({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return ExpandableFab(
      type: ExpandableFabType.up,
      childrenAnimation: ExpandableFabAnimation.none,
      distance: 70,
      children:
          selectedIndex == 0
              ? [
                Row(
                  spacing: 4,
                  children: [
                    Text("Criar Lista"),
                    FloatingActionButton.small(
                      heroTag: null,
                      child: const Icon(Icons.add),
                      onPressed:
                          () => context.push(
                            '/nova-lista',
                            extra: context.read<ListasBloc>(),
                          ),
                    ),
                  ],
                ),
                Row(
                  spacing: 4,
                  children: [
                    Text("Entrar em uma lista"),
                    FloatingActionButton.small(
                      heroTag: null,
                      child: const Icon(Icons.login),
                      onPressed:
                          () => context.push(
                            '/join-list',
                            extra: context.read<ListasBloc>(),
                          ),
                    ),
                  ],
                ),
              ]
              : [
                Row(
                  spacing: 4,
                  children: [
                    Text("Enviar Nota Fiscal"),
                    FloatingActionButton.small(
                      heroTag: null,
                      child: const Icon(Icons.qr_code_2),
                      onPressed: () => context.push('/enviar-nfe'),
                    ),
                  ],
                )
              ],
    );
  }
}
