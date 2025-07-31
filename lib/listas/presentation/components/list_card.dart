import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/shared/entities/unit.dart';
import 'package:go_router/go_router.dart';

class ListCard extends StatelessWidget {
  final ListaCompra list;
  final List<Unit> units;

  const ListCard({super.key, required this.list, required this.units});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          context.push('/list/${list.id}');
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
                style: Theme.of(
                  context,
                ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
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
  }
}
