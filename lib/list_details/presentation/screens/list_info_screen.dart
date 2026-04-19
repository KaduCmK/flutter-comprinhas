import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/core/models/image_upload_data.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/bloc/listas_bloc.dart';
import 'package:flutter_comprinhas/main.dart';
import 'package:image_picker/image_picker.dart';

class ListInfoScreen extends StatefulWidget {
  final String listId;

  const ListInfoScreen({super.key, required this.listId});

  @override
  State<ListInfoScreen> createState() => _ListInfoScreenState();
}

class _ListInfoScreenState extends State<ListInfoScreen> {
  bool _isUploadingBackgroundImage = false;

  Future<void> _pickAndUploadImage() async {
    final listasBloc = context.read<ListasBloc>();
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (!mounted || pickedFile == null) return;

    setState(() => _isUploadingBackgroundImage = true);
    final imageBytes = await pickedFile.readAsBytes();
    if (!mounted) return;
    final currentList = _resolveList(listasBloc.state);

    listasBloc.add(
      UpsertListEvent(
        currentList?.name ?? '',
        listId: widget.listId,
        backgroundImageUrl: currentList?.backgroundImage,
        imageData: ImageUploadData(
          bytes: imageBytes,
          fileName: pickedFile.name,
          contentType: pickedFile.mimeType,
        ),
      ),
    );
  }

  ListaCompra? _resolveList(ListasState state) {
    for (final list in state.lists) {
      if (list.id == widget.listId) return list;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<ListasBloc, ListasState>(
      listener: (context, state) {
        if (!_isUploadingBackgroundImage) return;

        if (state is ListasLoaded) {
          setState(() => _isUploadingBackgroundImage = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagem de fundo atualizada com sucesso!'),
            ),
          );
        } else if (state is ListasError) {
          setState(() => _isUploadingBackgroundImage = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: BlocBuilder<ListasBloc, ListasState>(
        builder: (context, state) {
          final currentList = _resolveList(state);
          if (currentList == null) {
            if (state is ListasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Informações da Lista')),
                body: Center(child: Text(state.message)),
              );
            }

            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final isOwner = supabase.auth.currentUser?.id == currentList.ownerId;
          final hasImage = currentList.backgroundImage != null;

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
                          currentList.name,
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
                          "Criada em ${currentList.createdAtFormatted}",
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
                            currentList.backgroundImage!,
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
                                _isUploadingBackgroundImage
                                    ? const CircularProgressIndicator()
                                    : CircleAvatar(
                                      backgroundColor: colorScheme.surface,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.add_photo_alternate,
                                        ),
                                        color: colorScheme.primary,
                                        tooltip: "Alterar imagem de fundo",
                                        onPressed:
                                            state is ListasLoading
                                                ? null
                                                : _pickAndUploadImage,
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
                                      "Participantes (${currentList.members.length})",
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
                                  itemCount: currentList.members.length,
                                  separatorBuilder:
                                      (context, index) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final member = currentList.members[index];
                                    final isMemberOwner =
                                        member.user.id == currentList.ownerId;
                                    final url =
                                        member
                                            .user
                                            .userMetadata?["avatar_url"] ??
                                        '';

                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        backgroundImage:
                                            url.isNotEmpty
                                                ? NetworkImage(url)
                                                : null,
                                        child:
                                            url.isEmpty
                                                ? const Icon(Icons.person)
                                                : null,
                                      ),
                                      title: Text(
                                        member.user.userMetadata?["name"] ??
                                            'Usuário',
                                      ),
                                      subtitle: Text(member.user.email ?? ''),
                                      trailing:
                                          isMemberOwner
                                              ? Chip(
                                                label: const Text('Dono'),
                                                backgroundColor:
                                                    colorScheme
                                                        .primaryContainer,
                                              )
                                              : null,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Detalhes da Lista',
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    Icons.calendar_today_outlined,
                                    color: colorScheme.primary,
                                  ),
                                  title: const Text('Data de Criação'),
                                  subtitle: Text(
                                    currentList.createdAtFormatted,
                                  ),
                                ),
                                const Divider(),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    Icons.currency_exchange,
                                    color: colorScheme.primary,
                                  ),
                                  title: const Text('Previsão de Preços'),
                                  subtitle: Text(
                                    currentList.priceForecastEnabled
                                        ? 'Ativada'
                                        : 'Desativada',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
