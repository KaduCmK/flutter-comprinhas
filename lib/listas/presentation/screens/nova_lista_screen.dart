import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/core/models/image_upload_data.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/bloc/listas_bloc.dart';
import 'package:flutter_comprinhas/core/config/service_locator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class NovaListaScreen extends StatefulWidget {
  final String? listId;

  const NovaListaScreen({super.key, this.listId});

  @override
  State<NovaListaScreen> createState() => _NovaListaScreenState();
}

class _NovaListaScreenState extends State<NovaListaScreen> {
  final _nameController = TextEditingController();
  Uint8List? _selectedImageBytes;
  ImageUploadData? _selectedImageData;
  String? _existingImageUrl;
  bool _isSubmitting = false;
  Future<ListaCompra?>? _listFuture;

  bool get _isEditMode => widget.listId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _listFuture = sl<ListasRepository>().getListById(widget.listId!);
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
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = imageBytes;
        _selectedImageData = ImageUploadData(
          bytes: imageBytes,
          fileName: pickedFile.name,
          contentType: pickedFile.mimeType,
        );
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
        listId: widget.listId,
        backgroundImageUrl: _existingImageUrl,
        imageData: _selectedImageData,
      ),
    );
  }

  void _applyListData(ListaCompra? list) {
    if (list == null) return;
    if (_nameController.text.isNotEmpty) return;

    _nameController.text = list.name;
    _existingImageUrl = list.backgroundImage;
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
      child: FutureBuilder<ListaCompra?>(
        future: _listFuture,
        builder: (context, snapshot) {
          if (_isEditMode && snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (_isEditMode && snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Editar Lista')),
              body: const Center(
                child: Text('Não foi possível carregar a lista.'),
              ),
            );
          }

          _applyListData(snapshot.data);

          return Scaffold(
            appBar: AppBar(
              title: Text('${_isEditMode ? 'Editar' : 'Nova'} Lista'),
            ),
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
                              _selectedImageBytes != null
                                  ? DecorationImage(
                                    image: MemoryImage(_selectedImageBytes!),
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
                            _selectedImageBytes == null &&
                                    _existingImageUrl == null
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
          );
        },
      ),
    );
  }
}
