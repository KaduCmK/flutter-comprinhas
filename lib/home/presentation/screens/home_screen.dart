import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comprinhas"),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: SafeArea(child: Column()),
      bottomNavigationBar: NavigationBar(destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home),
          label: "Listas",
        ),
        NavigationDestination(
          icon: const Icon(Icons.receipt_long),
          label: "Notas Fiscais",
        ),
      ]),
    );
  }
}
