import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/bloc/listas_bloc.dart';
import 'package:flutter_comprinhas/shared/entities/unit.dart';
import 'package:go_router/go_router.dart';

class ListCard extends StatelessWidget {
  final ListaCompra list;
  final List<Unit> units;

  const ListCard({super.key, required this.list, required this.units});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MenuAnchor(
      builder: (context, controller, child) {
        return Card(
          elevation: 2,
          child: InkWell(
            onTap: () {
              context.push('/list/${list.id}');
            },
            onLongPress: () {
              if (controller.isOpen)
                controller.close();
              else
                controller.open();
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.name,
                    style: textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    spacing: 2,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 16),
                      Text(list.createdAtFormatted),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      menuChildren: [
        MenuItemButton(
          leadingIcon: Icon(Icons.edit, color: colorScheme.primary),
          child: Text("Editar", style: TextStyle(color: colorScheme.primary)),
          onPressed: () {
            context.push(
              'nova-lista',
              extra: {'bloc': context.read<ListasBloc>(), 'list': list},
            );
          },
        ),
        MenuItemButton(
          leadingIcon: Icon(Icons.delete, color: colorScheme.error),
          child: Text("Deletar", style: TextStyle(color: colorScheme.error)),
          onPressed: () {
            context.read<ListasBloc>().add(DeleteListEvent(list.id));
          },
        ),
      ],
    );
  }
}
