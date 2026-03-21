import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/core/config/service_locator.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/product_match.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';

class PrecoSugeridoChip extends StatelessWidget {
  final String listItemId;
  final num? precoSugerido;

  const PrecoSugeridoChip({
    super.key,
    required this.listItemId,
    this.precoSugerido,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      avatar: Icon(Icons.auto_awesome, size: 16, color: colorScheme.primary),
      label: Text(
        "R\$ ${precoSugerido?.toStringAsFixed(2) ?? '--'}",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onPressed: () => _showMatchesDialog(context),
    );
  }

  void _showMatchesDialog(BuildContext context) {
    final repository = sl<ListasRepository>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Sugestões de Preço",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500, // Força uma largura maior para melhor legibilidade
            child: FutureBuilder<List<ProductMatch>>(
              future: repository.getProductMatches(listItemId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Text("Erro ao carregar sugestões: ${snapshot.error}");
                }

                final matches = snapshot.data ?? [];

                if (matches.isEmpty) {
                  return const Text(
                      "Nenhum produto similar encontrado para estimar o preço.");
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Selecione um produto para definir o preço aproximado:",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: matches.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final match = matches[index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              match.productName,
                              style: const TextStyle(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              "Similaridade: ${(match.similarityScore * 100).toStringAsFixed(1)}%",
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Text(
                              "R\$ ${match.price?.toStringAsFixed(2) ?? '--'}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            onTap: match.price == null
                                ? null
                                : () async {
                                    await repository.updatePrecoSugerido(
                                      listItemId,
                                      match.price!,
                                    );
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text("Preço atualizado!"),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                          );
                        },
                      ),
                    ),
                    const Divider(thickness: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Preço Atual:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "R\$ ${precoSugerido?.toStringAsFixed(2) ?? '--'}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Fechar"),
            ),
          ],
        );
      },
    );
  }
}
