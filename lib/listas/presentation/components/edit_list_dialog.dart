import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/bloc/listas_bloc.dart';
import 'package:go_router/go_router.dart';

class EditListDialog extends StatefulWidget {
  final ListaCompra list;

  const EditListDialog({super.key, required this.list});

  @override
  State<EditListDialog> createState() => _EditListDialogState();
}

class _EditListDialogState extends State<EditListDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.list.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final newName = _nameController.text;
    if (newName.isEmpty) {
      // Maybe show a snackbar? For now, just do nothing.
      return;
    }
    context.read<ListasBloc>().add(
      UpsertListEvent(newName, listId: widget.list.id),
    );
    context.pop();
  }

  void _delete() {
    context.read<ListasBloc>().add(DeleteListEvent(widget.list.id));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Editar Lista'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da lista',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: const Text('Salvar'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _delete,
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error),
              ),
              child: const Text('Excluir'),
            ),
          ],
        ),
      ),
    );
  }
}
