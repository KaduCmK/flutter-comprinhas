import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/qr_code_dialog.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details_bloc.dart';
import 'package:go_router/go_router.dart';

class ListDetailsAppbarActions extends StatelessWidget {
  final ListDetailsState state;

  const ListDetailsAppbarActions({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      spacing: 4,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => context.read<ListDetailsBloc>().add(
                TogglePriceForecastEvent(),
          ),
          icon: Icon(
            Icons.currency_exchange,
            color: colorScheme.primary.withValues(
              alpha: state.list?.priceForecastEnabled ?? false ? 1 : 0.5,
            ),
          ),
        ),
        MenuAnchor(
          menuChildren: [
            MenuItemButton(
              leadingIcon: Icon(Icons.sort_by_alpha),
              child: Text("Alfabético"),
              onPressed:
                  () => context.read<ListDetailsBloc>().add(
                    SortListEvent(SortOption.name),
                  ),
            ),
            MenuItemButton(
              leadingIcon: Icon(Icons.event),
              child: Text(
                "Quantidade",
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed:
                  () => context.read<ListDetailsBloc>().add(
                    SortListEvent(SortOption.date),
                  ),
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
        MenuAnchor(
          menuChildren: [
            MenuItemButton(
              leadingIcon: Icon(Icons.qr_code),
              child: Text("Gerar QR Code"),
              onPressed:
                  () => showDialog(
                    context: context,
                    builder: (_) => QrCodeDialog(listId: state.list!.id),
                  ),
            ),
            MenuItemButton(
              leadingIcon: Icon(Icons.link),
              child: Text("Copiar código"),
              onPressed: () {
                final encodedListId = base64Url.encode(
                  utf8.encode(state.list!.id),
                );
                final listCode = 'comprinhas://join/$encodedListId';
                Clipboard.setData(ClipboardData(text: listCode)).then((_) {
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
    );
  }
}
