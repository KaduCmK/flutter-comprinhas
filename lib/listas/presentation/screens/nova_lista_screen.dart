import 'package:flutter/material.dart';

class NovaListaScreen extends StatelessWidget {
  const NovaListaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Lista')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Nome da Lista:"),
              TextField(
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Text("Imagem de fundo (opcional):"),
              TextField(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                enabled: false,
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () {}, child: Text("Criar Lista")),
            ],
          ),
        ),
      ),
    );
  }
}
