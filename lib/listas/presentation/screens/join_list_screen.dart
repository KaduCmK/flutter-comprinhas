import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class JoinListScreen extends StatefulWidget {
  const JoinListScreen({super.key});

  @override
  State<JoinListScreen> createState() => _JoinListScreenState();
}

class _JoinListScreenState extends State<JoinListScreen> {
  final TextEditingController listIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkClipboard();
  }

  @override
  void dispose() {
    listIdController.dispose();
    super.dispose();
  }

  void _checkClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final clipboardText = clipboardData?.text;

    if (clipboardText != null &&
        clipboardText.startsWith('comprinhas://join/') &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Um código de lista foi colado da sua área de transferência.",
          ),
        ),
      );
      setState(() {
        listIdController.text = clipboardText;
      });
    }
  }

  void _joinListById() {
    debugPrint(listIdController.text);
    final uri = Uri.parse(listIdController.text);
    final encodedId = uri.pathSegments.last;
    context.replace('/join/$encodedId');
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
