import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:intl/intl.dart';

class ListInfoScreen extends StatelessWidget {
  final ListaCompra list;

  const ListInfoScreen({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Informações da Lista"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              list.name,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Criada em ${list.createdAtFormatted}",
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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
                          "Participantes (${list.members.length})",
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
                      itemCount: list.members.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final member = list.members[index];
                        final isOwner = member.user.id == list.ownerId;
                        final url = member.user.userMetadata?["avatar_url"] ??
                            member.user.userMetadata?["picture"];
                        final name = member.user.userMetadata?["name"] ??
                            member.user.userMetadata?["full_name"] ??
                            'Usuário';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundImage: url != null ? NetworkImage(url) : null,
                            child: url == null ? const Icon(Icons.person) : null,
                          ),
                          title: Row(
                            children: [
                              Text(name),
                              if (isOwner) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.workspace_premium, color: Colors.amber, size: 16),
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
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implementar exclusão
                // Como não temos o BLoC passado para cá ainda, podemos só mostrar um snackbar por enquanto
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Use a tela inicial para excluir a lista.')),
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
    );
  }
}
