import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/listas_screen.dart';
import 'package:flutter_comprinhas/shared/widgets/user_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<Widget> _destinations = [
    ListasScreen(),
    Placeholder(child: Center(child: Text("Notas Fiscais"))),
  ];

  int _selectedIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    _onPageChanged(index);
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 225),
      curve: Curves.ease,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comprinhas"),
        leading: const UserAvatar(),
      ),
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton(
                onPressed:
                    () => Navigator.of(context).pushNamed('/listas/nova_lista'),
                child: const Icon(Icons.add),
              )
              : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: PageView.builder(
            itemCount: _destinations.length,
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return _destinations[index];
            },
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.list), label: "Listas"),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long),
            label: "Notas Fiscais",
          ),
        ],
      ),
    );
  }
}
