import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/new_item_dialog.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details_bloc.dart';

class ListDetailsAppBar extends StatelessWidget {
  final double topCardHeight;
  const ListDetailsAppBar({super.key, required this.topCardHeight});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListDetailsBloc, ListDetailsState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SizedBox(
            height: topCardHeight,
            child: Card(
              elevation: 2,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.list!.name,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed:
                              () => showDialog(
                                context: context,
                                builder: (_) {
                                  return BlocProvider.value(
                                    value: context.read<ListDetailsBloc>(),
                                    child: NewItemDialog(),
                                  );
                                },
                              ),
                          child: const Text("Adicionar"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
