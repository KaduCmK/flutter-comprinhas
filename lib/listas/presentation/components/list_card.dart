import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/listas/presentation/components/edit_list_dialog.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/bloc/listas_bloc.dart';
import 'package:flutter_comprinhas/shared/entities/unit.dart';
import 'package:go_router/go_router.dart';

class ListCard extends StatelessWidget {
  final ListaCompra list;
  final List<Unit> units;

  const ListCard({super.key, required this.list, required this.units});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          context.push('/list/${list.id}');
        },
        onLongPress: () {
          showDialog(
            context: context,
            builder: (_) => BlocProvider.value(
              value: context.read<ListasBloc>(),
              child: EditListDialog(list: list),
            ),
          );
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(list.createdAtFormatted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
