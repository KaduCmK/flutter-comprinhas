import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/core/config/service_locator.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/bloc/listas_bloc.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/listas_screen.dart';
import 'package:flutter_comprinhas/shared/widgets/user_avatar.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:go_router/go_router.dart';

class HomeScreenProvider extends StatelessWidget {
  const HomeScreenProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              ListasBloc(repository: sl<ListasRepository>())
                ..add(GetListsEvent()),
      child: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final List<Widget> _destinations = [
    const ListasScreen(),
    const Placeholder(child: Center(child: Text("Notas Fiscais"))),
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
      duration: const Duration(milliseconds: 225),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        type: ExpandableFabType.up,
        childrenAnimation: ExpandableFabAnimation.none,
        distance: 70,
        children: [
          Row(
            spacing: 4,
            children: [
              Text("Criar Lista"),
              FloatingActionButton.small(
                heroTag: null,
                child: const Icon(Icons.add),
                onPressed:
                    () => context.push(
                      '/nova-lista',
                      extra: context.read<ListasBloc>(),
                    ),
              ),
            ],
          ),
          Row(
            spacing: 4,
            children: [
              Text("Entrar em uma lista"),
              FloatingActionButton.small(
                heroTag: null,
                child: const Icon(Icons.login),
                onPressed:
                    () => context.push(
                      '/join-list',
                      extra: context.read<ListasBloc>(),
                    ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
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
