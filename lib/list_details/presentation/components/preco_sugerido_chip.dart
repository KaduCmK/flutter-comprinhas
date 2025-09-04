import 'package:flutter/material.dart';

class PrecoSugeridoChip extends StatelessWidget {
  final num? precoSugerido;

  const PrecoSugeridoChip({super.key, this.precoSugerido});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text("R\$ $precoSugerido"),
      onPressed:
          () => showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text("Itens sugeridos"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "O preço estimado deste item foi calculado a partir dos seguintes produtos:",
                      ),
                      
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Fechar"),
                    ),
                  ],
                ),
          ),
    );
  }
}
