import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details/list_details_bloc.dart';

class NewItemDialog extends StatefulWidget {
  const NewItemDialog({super.key});

  @override
  State<NewItemDialog> createState() => _NewItemDialogState();
}

class _NewItemDialogState extends State<NewItemDialog> {
  final _formKey = GlobalKey<FormState>();

  final _itemNameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  
  final _unitController = TextEditingController();
  String? _selectedUnitId;

  final _amountController = TextEditingController(text: "1");
  final _amountFocusNode = FocusNode();


  @override
  void dispose() {
    _itemNameController.dispose();
    _amountController.dispose();
    _unitController.dispose();
    _nameFocusNode.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedUnitId == null) {
        // Opcional: mostrar um snackbar se nenhuma unidade for selecionada
        return;
      }

      context.read<ListDetailsBloc>().add(
        AddItemToList(
          itemName: _itemNameController.text.trim(),
          amount: num.parse(_amountController.text.replaceAll(',', '.')),
          unitId: _selectedUnitId!,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListDetailsBloc, ListDetailsState>(
      builder: (context, state) {
        final units = state.units ?? [];
        final initialUnit = units.firstWhere(
          (u) => u.abbreviation == "un",
          orElse: () => units.first,
        );

        _selectedUnitId ??= initialUnit.id;

        return AlertDialog(
          title: const Text("Adicionar Novo Item"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: "Qtd."),
                        onFieldSubmitted: (_) => _nameFocusNode.requestFocus(),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Req.";
                          if (num.tryParse(value.replaceAll(',', '.')) == null)
                            return "Inválido";
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: DropdownMenu(
                        controller: _unitController,
                        initialSelection: initialUnit.id,
                        label: const Text("Unidade"),
                        expandedInsets: EdgeInsets.zero,
                        dropdownMenuEntries:
                            units
                                .map(
                                  (unit) => DropdownMenuEntry(
                                    value: unit.id,
                                    label: unit.name,
                                  ),
                                )
                                .toList(),
                        onSelected: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedUnitId = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _itemNameController,
                  focusNode: _nameFocusNode,
                  autocorrect: true,
                  decoration: const InputDecoration(labelText: "Nome do item"),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submitForm(),
                  validator:
                      (value) =>
                          (value?.isEmpty ?? true) ? "Campo obrigatório" : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(onPressed: _submitForm, child: const Text("Salvar")),
          ],
        );
      },
    );
  }
}
