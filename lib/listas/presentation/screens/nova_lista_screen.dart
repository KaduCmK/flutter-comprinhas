import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/bloc/listas_bloc.dart';

class NovaListaScreen extends StatelessWidget {
  final _nameController = TextEditingController();

  NovaListaScreen({super.key});

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
                controller: _nameController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Text("Imagem de fundo (opcional):"),
              TextField(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                enabled: false,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  context.read<ListasBloc>().add(
                    CreateListEvent(_nameController.text),
                  );
                  Navigator.pop(context);
                },
                child: Text("Criar Lista"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
