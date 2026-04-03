import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/core/config/service_locator.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:flutter_comprinhas/main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ListInfoScreen extends StatefulWidget {
  final ListaCompra list;

  const ListInfoScreen({super.key, required this.list});

  @override
  State<ListInfoScreen> createState() => _ListInfoScreenState();
}

class _ListInfoScreenState extends State<ListInfoScreen> {
  late ListaCompra _currentList;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _currentList = widget.list;
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final repository = sl<ListasRepository>();
      final file = File(pickedFile.path);

      final uploadedUrl = await repository.uploadBackgroundImage(
        file,
        _currentList.id,
      );

      if (uploadedUrl != null) {
        await repository.upsertList(
          _currentList.name,
          listId: _currentList.id,
          backgroundImageUrl: uploadedUrl,
        );

        // Atualiza a UI localmente
        setState(() {
          _currentList = ListaCompra(
            id: _currentList.id,
            name: _currentList.name,
            ownerId: _currentList.ownerId,
            createdAt: _currentList.createdAt,
            cartMode: _currentList.cartMode,
            priceForecastEnabled: _currentList.priceForecastEnabled,
            members: _currentList.members,
            backgroundImage: uploadedUrl,
          );
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagem de fundo atualizada com sucesso!'),
            ),
          );
        }
      } else {
        throw 'Falha ao fazer upload da imagem.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isOwner = supabase.auth.currentUser?.id == _currentList.ownerId;
    final hasImage = _currentList.backgroundImage != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 16,
                bottom: 16,
                right: 16,
              ),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentList.name,
                    style: TextStyle(
                      color: hasImage ? Colors.white : null,
                      fontWeight: FontWeight.bold,
                      shadows:
                          hasImage
                              ? [
                                const Shadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                ),
                              ]
                              : null,
                    ),
                  ),
                  Text(
                    "Criada em ${_currentList.createdAtFormatted}",
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          hasImage
                              ? Colors.white70
                              : colorScheme.onSurfaceVariant,
                      shadows:
                          hasImage
                              ? [
                                const Shadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                ),
                              ]
                              : null,
                    ),
                  ),
                ],
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage) ...[
                    Image.network(
                      _currentList.backgroundImage!,
                      fit: BoxFit.cover,
                      frameBuilder: (
                        context,
                        child,
                        frame,
                        wasSynchronouslyLoaded,
                      ) {
                        if (wasSynchronouslyLoaded) return child;
                        return AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          child: child,
                        );
                      },
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black54,
                            Colors.transparent,
                            Colors.black87,
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(color: colorScheme.surfaceContainerHighest),
                    Center(
                      child: Icon(
                        Icons.shopping_basket,
                        size: 80,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                  if (isOwner)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      right: 16,
                      child:
                          _isUploading
                              ? const CircularProgressIndicator()
                              : CircleAvatar(
                                backgroundColor: colorScheme.surface,
                                child: IconButton(
                                  icon: const Icon(Icons.add_photo_alternate),
                                  color: colorScheme.primary,
                                  tooltip: "Alterar imagem de fundo",
                                  onPressed: _pickAndUploadImage,
                                ),
                              ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people),
                              const SizedBox(width: 8),
                              Text(
                                "Participantes (${_currentList.members.length})",
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _currentList.members.length,
                            separatorBuilder:
                                (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final member = _currentList.members[index];
                              final isMemberOwner =
                                  member.user.id == _currentList.ownerId;
                              final url =
                                  member.user.userMetadata?["avatar_url"] ??
                                  member.user.userMetadata?["picture"];
                              final name =
                                  member.user.userMetadata?["name"] ??
                                  member.user.userMetadata?["full_name"] ??
                                  'Usuário';

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundImage:
                                      url != null ? NetworkImage(url) : null,
                                  child:
                                      url == null
                                          ? const Icon(Icons.person)
                                          : null,
                                ),
                                title: Row(
                                  children: [
                                    Text(name),
                                    if (isMemberOwner) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.workspace_premium,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  "Entrou em ${DateFormat('dd/MM/yyyy').format(member.joinedAt)}",
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isOwner)
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implementar exclusão
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Use a tela inicial para excluir a lista.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text("Excluir Lista"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        backgroundColor: colorScheme.errorContainer,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
