import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/qr_code_dialog.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details/list_details_bloc.dart';
import 'package:go_router/go_router.dart';

class ListDetailsAppbarActions extends StatelessWidget {
  final ListDetailsState state;

  const ListDetailsAppbarActions({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        IconButton(
          onPressed:
              () => context.read<ListDetailsBloc>().add(TogglePriceForecast()),
          tooltip: "Previsão de preços",
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
              leadingIcon: Icon(
                state.sortOption == SortOption.name
                    ? Icons.check_circle
                    : Icons.sort_by_alpha,
                color:
                    state.sortOption == SortOption.name
                        ? colorScheme.primary
                        : null,
              ),
              child: Text(
                "Alfabético",
                style: TextStyle(
                  fontWeight:
                      state.sortOption == SortOption.name
                          ? FontWeight.bold
                          : null,
                ),
              ),
              onPressed:
                  () => context.read<ListDetailsBloc>().add(
                    SortList(SortOption.name, state.sortOrder),
                  ),
            ),
            MenuItemButton(
              leadingIcon: Icon(
                state.sortOption == SortOption.date
                    ? Icons.check_circle
                    : Icons.calendar_today,
                color:
                    state.sortOption == SortOption.date
                        ? colorScheme.primary
                        : null,
              ),
              child: Text(
                "Data de Adição",
                style: TextStyle(
                  fontWeight:
                      state.sortOption == SortOption.date
                          ? FontWeight.bold
                          : null,
                ),
              ),
              onPressed:
                  () => context.read<ListDetailsBloc>().add(
                    SortList(SortOption.date, state.sortOrder),
                  ),
            ),
            MenuItemButton(
              leadingIcon: Icon(
                state.sortOption == SortOption.price
                    ? Icons.check_circle
                    : Icons.attach_money,
                color:
                    state.sortOption == SortOption.price
                        ? colorScheme.primary
                        : null,
              ),
              child: Text(
                "Preço Sugerido",
                style: TextStyle(
                  fontWeight:
                      state.sortOption == SortOption.price
                          ? FontWeight.bold
                          : null,
                ),
              ),
              onPressed:
                  () => context.read<ListDetailsBloc>().add(
                    SortList(SortOption.price, state.sortOrder),
                  ),
            ),
            const Divider(),
            MenuItemButton(
              leadingIcon: Icon(
                state.sortOrder == SortOrder.ascending
                    ? Icons.check_circle
                    : Icons.arrow_upward,
                color:
                    state.sortOrder == SortOrder.ascending
                        ? colorScheme.primary
                        : null,
              ),
              child: Text(
                "Crescente",
                style: TextStyle(
                  fontWeight:
                      state.sortOrder == SortOrder.ascending
                          ? FontWeight.bold
                          : null,
                ),
              ),
              onPressed:
                  () => context.read<ListDetailsBloc>().add(
                    SortList(state.sortOption, SortOrder.ascending),
                  ),
            ),
            MenuItemButton(
              leadingIcon: Icon(
                state.sortOrder == SortOrder.descending
                    ? Icons.check_circle
                    : Icons.arrow_downward,
                color:
                    state.sortOrder == SortOrder.descending
                        ? colorScheme.primary
                        : null,
              ),
              child: Text(
                "Decrescente",
                style: TextStyle(
                  fontWeight:
                      state.sortOrder == SortOrder.descending
                          ? FontWeight.bold
                          : null,
                ),
              ),
              onPressed:
                  () => context.read<ListDetailsBloc>().add(
                    SortList(state.sortOption, SortOrder.descending),
                  ),
            ),
          ],
          builder: (context, controller, child) {
            IconData sortIcon;
            if (state.sortOption == SortOption.name) {
              sortIcon = Icons.sort_by_alpha;
            } else if (state.sortOption == SortOption.price) {
              sortIcon = Icons.monetization_on;
            } else {
              sortIcon = Icons.calendar_today;
            }

            return IconButton(
              onPressed: () => controller.open(),
              tooltip: "Ordenação",
              icon: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Icon(sortIcon),
                  Transform.translate(
                    offset: const Offset(4, 4),
                    child: Icon(
                      state.sortOrder == SortOrder.ascending
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        IconButton(
          onPressed: () => context.push('/list/${state.list!.id}/history'),
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
