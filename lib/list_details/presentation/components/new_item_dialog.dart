import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details_bloc.dart';

class NewItemDialog extends StatelessWidget {
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(
    text: "1",
  );

  NewItemDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListDetailsBloc, ListDetailsState>(
      builder: (context, state) {
        if (state is! ListDetailsLoaded) return const SizedBox.shrink();

        final units = state.units;

        return AlertDialog(
          title: const Text("Novo Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _itemNameController),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    child: TextField(controller: _amountController),
                  ),
                  SizedBox(
                    width: 128,
                    child: DropdownMenu(
                      expandedInsets: EdgeInsets.zero,
                      controller: _unitController,
                      initialSelection:
                          units!.singleWhere((u) => u.abbreviation == "un").id,
                      dropdownMenuEntries: List.generate(
                        units.length,
                        (index) => DropdownMenuEntry(
                          value: units[index].id,
                          label: units[index].name,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Salvar"),
              onPressed: () {
                final unit = state.units!.singleWhere(
                  (u) => u.name == _unitController.text,
                );
                context.read<ListDetailsBloc>().add(
                  AddItemToListEvent(
                    itemName: _itemNameController.text,
                    amount: num.parse(_amountController.text),
                    unitId: unit.id,
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
