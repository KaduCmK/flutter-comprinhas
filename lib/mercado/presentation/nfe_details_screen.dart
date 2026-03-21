import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/shared/entities/purchase_history.dart';

class NfeDetailsScreen extends StatelessWidget {
  final PurchaseHistory purchase;

  const NfeDetailsScreen({super.key, required this.purchase});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalhes da Nota"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            "Nota de ${purchase.confirmedBy} carregada com sucesso!\nID: ${purchase.id}\n${purchase.items.length} itens encontrados.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
