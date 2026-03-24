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
  bool _isSaving = false;

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
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isSaving = true);
    
    context.read<ListasBloc>().add(
      UpsertListEvent(newName, listId: widget.list.id),
    );
  }

  void _delete() {
    final listasBloc = context.read<ListasBloc>();
    showDialog(
      context: context,
      builder:
          (confirmContext) => AlertDialog(
            title: const Text('Excluir Lista'),
            content: const Text(
              'Tem certeza que deseja excluir esta lista e todos os seus itens? Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(confirmContext),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(confirmContext);
                  listasBloc.add(DeleteListEvent(widget.list.id));
                  if (mounted) Navigator.pop(context);
                },
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<ListasBloc, ListasState>(
      listenWhen: (previous, current) => previous is ListasLoading && current is! ListasLoading,
      listener: (context, state) {
        if (state is ListasLoaded) {
          if (mounted) Navigator.pop(context);
        } else if (state is ListasError) {
          setState(() => _isSaving = false);
        }
      },
      child: AlertDialog(
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
                enabled: !_isSaving,
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 16),
              if (_isSaving)
                const Center(child: CircularProgressIndicator())
              else ...[
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
            ],
          ),
        ),
      ),
    );
  }
}
