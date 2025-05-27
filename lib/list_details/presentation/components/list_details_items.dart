// list_details_items.dart
import 'package:flutter/material.dart';

class ListDetailsItems extends StatelessWidget {
  const ListDetailsItems({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        color: Colors.amber
      ),
      child: Column(
        children: [
          // Handle para arrastar
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
              child: Container(
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          // Conteúdo "vazio" - um Container expandido para preencher o Card
          Expanded(child: Placeholder()),
        ],
      ),
    );
  }
}
