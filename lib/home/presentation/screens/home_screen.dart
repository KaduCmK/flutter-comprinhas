import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/core/config/service_locator.dart';
import 'package:flutter_comprinhas/home/presentation/components/home_fab.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/bloc/listas_bloc.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/listas_screen.dart';
import 'package:flutter_comprinhas/mercado/presentation/bloc/mercado_bloc.dart';
import 'package:flutter_comprinhas/mercado/presentation/mercado_screen.dart';
import 'package:flutter_comprinhas/shared/widgets/user_avatar.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

class HomeScreenProvider extends StatelessWidget {
  const HomeScreenProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create:
              (context) => ListasBloc(repository: sl())..add(GetListsEvent()),
        ),
        BlocProvider(create: (_) => MercadoBloc(mercadoRepository: sl())),
      ],
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
  static final List<Widget> _destinations = [];

  int _selectedIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _destinations.addAll([ListasScreen(), MercadoScreen()]);
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
      floatingActionButton: HomeFab(selectedIndex: _selectedIndex),
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
            icon: const Icon(Icons.store),
            label: "Mercados",
          ),
        ],
      ),
    );
  }
}
