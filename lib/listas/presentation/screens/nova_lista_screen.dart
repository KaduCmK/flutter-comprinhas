import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/bloc/listas_bloc.dart';
import 'package:go_router/go_router.dart';

class NovaListaScreen extends StatefulWidget {
  final ListaCompra? listToEdit;

  const NovaListaScreen({super.key, this.listToEdit});

  @override
  State<NovaListaScreen> createState() => _NovaListaScreenState();
}

class _NovaListaScreenState extends State<NovaListaScreen> {
  final _nameController = TextEditingController();
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.listToEdit != null) {
      _isEditMode = true;
      _nameController.text = widget.listToEdit!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final listName = _nameController.text;
    if (listName.isEmpty) {
      // TODO: mostrar snackbar
      return;
    }

    context.read<ListasBloc>().add(
      UpsertListEvent(
        listName,
        listId: _isEditMode ? widget.listToEdit!.id : null,
      ),
    );
    context.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${_isEditMode ? 'Editar' : 'Nova'} Lista')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Nome da Lista:"),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(border: OutlineInputBorder()), onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              Text("Imagem de fundo (opcional):"),
              TextField(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                enabled: false,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submit,
                child: Text(_isEditMode ? "Salvar" : "Criar Lista"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
