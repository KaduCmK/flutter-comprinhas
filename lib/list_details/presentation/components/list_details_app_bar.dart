import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_details_appbar_actions.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/new_item_dialog.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details/list_details_bloc.dart';

class ListDetailsAppBar extends StatelessWidget {
  const ListDetailsAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<ListDetailsBloc, ListDetailsState>(
      builder: (context, state) {
        return SafeArea(
          child: Card(
            elevation: 2,
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.list?.name ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.headlineMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                "Total estimado: R\$ --,--",
                                style: textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                      ListDetailsAppbarActions(state: state),
                    ],
                  ),
                  state.isLoading
                      ? const LinearProgressIndicator()
                      : SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
