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

  bool _isNlpMode = false;

  final _itemNameController = TextEditingController();
  final _nameFocusNode = FocusNode();

  final _unitController = TextEditingController();
  String? _selectedUnitId;

  final _amountController = TextEditingController(text: "1");
  final _amountFocusNode = FocusNode();

  final _nlpController = TextEditingController();
  final _nlpFocusNode = FocusNode();

  @override
  void dispose() {
    _itemNameController.dispose();
    _amountController.dispose();
    _unitController.dispose();
    _nameFocusNode.dispose();
    _amountFocusNode.dispose();
    _nlpController.dispose();
    _nlpFocusNode.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_isNlpMode) {
      final query = _nlpController.text.trim();
      if (query.isNotEmpty) {
        context.read<ListDetailsBloc>().add(
          AddNaturalLanguageItemToList(query),
        );
      }
    } else {
      if (_formKey.currentState?.validate() ?? false) {
        if (_selectedUnitId == null) {
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
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ListDetailsBloc, ListDetailsState>(
      listenWhen:
          (previous, current) => previous.isParsingNlp != current.isParsingNlp,
      listener: (context, state) {
        if (!state.isParsingNlp && _isNlpMode && state.error == null) {
          // If parsing finished successfully, close the dialog
          Navigator.of(context).pop();
        } else if (state.error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      builder: (context, state) {
        final units = state.units ?? [];
        final initialUnit = units.firstWhere(
          (u) => u.abbreviation == "un",
          orElse:
              () =>
                  units.isNotEmpty
                      ? units.first
                      : throw Exception("No units found"),
        );

        _selectedUnitId ??= initialUnit.id;

        return AlertDialog(
          title: const Text("Adicionar Novo Item"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Manual'),
                      icon: Icon(Icons.edit),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Com IA'),
                      icon: Icon(Icons.auto_awesome),
                    ),
                  ],
                  selected: {_isNlpMode},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _isNlpMode = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),
                if (_isNlpMode) ...[
                  TextFormField(
                    controller: _nlpController,
                    focusNode: _nlpFocusNode,
                    autofocus: true,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "O que você deseja comprar?",
                      hintText: "Ex: 1kg de carne moída, 2 pct de macarrão",
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submitForm(),
                  ),
                  if (state.isParsingNlp) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 8),
                    const Center(child: Text("Interpretando...")),
                  ],
                ] else ...[
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
                          onFieldSubmitted:
                              (_) => _nameFocusNode.requestFocus(),
                          validator: (value) {
                            if (value == null || value.isEmpty) return "Req.";
                            if (num.tryParse(value.replaceAll(',', '.')) ==
                                null)
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
                    decoration: const InputDecoration(
                      labelText: "Nome do item",
                    ),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submitForm(),
                    validator:
                        (value) =>
                            (value?.isEmpty ?? true)
                                ? "Campo obrigatório"
                                : null,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  state.isParsingNlp ? null : () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            FilledButton(
              onPressed: state.isParsingNlp ? null : _submitForm,
              child: const Text("Salvar"),
            ),
          ],
        );
      },
    );
  }
}
