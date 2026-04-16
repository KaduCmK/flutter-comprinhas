import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/bloc/listas_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class NovaListaScreen extends StatefulWidget {
  final ListaCompra? listToEdit;

  const NovaListaScreen({super.key, this.listToEdit});

  @override
  State<NovaListaScreen> createState() => _NovaListaScreenState();
}

class _NovaListaScreenState extends State<NovaListaScreen> {
  final _nameController = TextEditingController();
  bool _isEditMode = false;
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.listToEdit != null) {
      _isEditMode = true;
      _nameController.text = widget.listToEdit!.name;
      _existingImageUrl = widget.listToEdit!.backgroundImage;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _existingImageUrl = null;
      });
    }
  }

  void _submit() {
    final listName = _nameController.text.trim();
    if (listName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe o nome da lista.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    context.read<ListasBloc>().add(
      UpsertListEvent(
        listName,
        listId: _isEditMode ? widget.listToEdit!.id : null,
        backgroundImageUrl: _existingImageUrl,
        imageFile: _selectedImage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<ListasBloc, ListasState>(
      listener: (context, state) {
        if (!_isSubmitting) return;

        if (state is ListasLoaded) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditMode
                    ? 'Lista salva com sucesso.'
                    : 'Lista criada com sucesso.',
              ),
            ),
          );
          context.pop();
        } else if (state is ListasError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text('${_isEditMode ? 'Editar' : 'Nova'} Lista')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Nome da Lista",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submit(),
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 24),
                Text(
                  "Imagem de fundo (opcional)",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _isSubmitting ? null : _pickImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
                      image:
                          _selectedImage != null
                              ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                              : _existingImageUrl != null
                              ? DecorationImage(
                                image: NetworkImage(_existingImageUrl!),
                                fit: BoxFit.cover,
                              )
                              : null,
                    ),
                    child:
                        _selectedImage == null && _existingImageUrl == null
                            ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 48,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Toque para escolher da galeria",
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            )
                            : Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CircleAvatar(
                                  backgroundColor: colorScheme.surface,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed:
                                        _isSubmitting ? null : _pickImage,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            _isEditMode ? "Salvar" : "Criar Lista",
                            style: const TextStyle(fontSize: 16),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
