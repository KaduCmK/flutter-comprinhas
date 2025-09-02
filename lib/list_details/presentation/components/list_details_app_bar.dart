import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/new_item_dialog.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/qr_code_dialog.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details_bloc.dart';
import 'package:go_router/go_router.dart';

class ListDetailsAppBar extends StatelessWidget {
  final double topCardHeight;

  const ListDetailsAppBar({super.key, required this.topCardHeight});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<ListDetailsBloc, ListDetailsState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SizedBox(
            height: topCardHeight,
            child: Card(
              elevation: 2,
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            state.list?.name ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.headlineMedium?.copyWith(
                              color:colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        MenuAnchor(
                          menuChildren: [
                            MenuItemButton(
                              leadingIcon: Icon(Icons.qr_code),
                              child: Text("Gerar QR Code"),
                              onPressed:
                                  () => showDialog(
                                    context: context,
                                    builder:
                                        (_) => QrCodeDialog(
                                          listId: state.list!.id,
                                        ),
                                  ),
                            ),
                            MenuItemButton(
                              leadingIcon: Icon(Icons.link),
                              child: Text("Copiar código"),
                              onPressed: () {
                                final encodedListId = base64Url.encode(
                                  utf8.encode(state.list!.id),
                                );
                                final listCode =
                                    'comprinhas://join/$encodedListId';
                                Clipboard.setData(
                                  ClipboardData(text: listCode),
                                ).then((_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          "Código copiado para a área de transferência",
                                        ),
                                      ),
                                    );
                                  }
                                });
                              },
                            ),
                          ],
                          builder:
                              (context, controller, child) => IconButton(
                                onPressed: () {
                                  if (controller.isOpen) {
                                    controller.close();
                                  } else {
                                    controller.open();
                                  }
                                },
                                icon: Icon(Icons.share),
                              ),
                        ),
                      ],
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

                        Row(
                          spacing: 4,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MenuAnchor(
                              menuChildren: [
                                MenuItemButton(
                                  leadingIcon: Icon(Icons.sort_by_alpha),
                                  child: Text("Alfabético"),
                                  onPressed: () => context
                                      .read<ListDetailsBloc>()
                                      .add(SortListEvent(SortOption.name)),
                                ),
                                MenuItemButton(
                                  leadingIcon: Icon(Icons.event),
                                  child: Text("Quantidade", style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),),
                                  onPressed: () => context
                                      .read<ListDetailsBloc>()
                                      .add(SortListEvent(SortOption.date)),
                                ),
                              ],
                              builder:
                                  (context, controller, child) => IconButton(
                                    onPressed: () => controller.open(),
                                    icon: Icon(Icons.sort),
                                  ),
                            ),
                            IconButton(
                              onPressed:
                                  () => context.push(
                                    '/list/${state.list!.id}/history',
                                    extra: context.read<ListDetailsBloc>(),
                                  ),
                              tooltip: "Histórico",
                              icon: Icon(Icons.history),
                            ),
                          ],
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
