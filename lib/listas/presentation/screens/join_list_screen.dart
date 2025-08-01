import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class JoinListScreen extends StatefulWidget {
  const JoinListScreen({super.key});

  @override
  State<JoinListScreen> createState() => _JoinListScreenState();
}

class _JoinListScreenState extends State<JoinListScreen> {
  final TextEditingController listIdController = TextEditingController();

  @override
  void dispose() {
    listIdController.dispose();
    super.dispose();
  }

  void _joinListById() {
    debugPrint(listIdController.text);
    context.replace('/join/${listIdController.text}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Entrar em uma Lista")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("ID da Lista:"),
            TextField(
              controller: listIdController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onSubmitted: (value) => _joinListById(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _joinListById,
              child: const Text("Entrar na Lista"),
            ),
          ],
        ),
      ),
    );
  }
}
