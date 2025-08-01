import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/app_theme.dart';
import 'package:flutter_comprinhas/auth/presentation/screens/login_screen.dart';
import 'package:flutter_comprinhas/auth/presentation/screens/splash_screen.dart';
import 'package:flutter_comprinhas/core/config/firebase_config.dart';
import 'package:flutter_comprinhas/core/config/service_locator.dart';
import 'package:flutter_comprinhas/global_cart/presentation/bloc/global_cart_bloc.dart';
import 'package:flutter_comprinhas/global_cart/presentation/global_cart_screen.dart';
import 'package:flutter_comprinhas/home/presentation/screens/home_screen.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/list_details_screen.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/bloc/listas_bloc.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/join_list_screen.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/nova_lista_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  configureServiceLocator();

  await configureFirebase();

  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    ShellRoute(
      builder: (context, state, child) {
        return BlocProvider(
          create:
              (context) =>
                  GlobalCartBloc(repository: sl())..add(LoadGlobalCartEvent()),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreenProvider(),
        ),
        GoRoute(
          path: '/carrinho',
          builder: (context, state) => const GlobalCartScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/list/:listId',
      builder: (context, state) {
        final listId = state.pathParameters['listId']!;
        return BlocProvider(
          create:
              (context) => ListDetailsBloc(
                client: supabase,
                repository: sl<ListasRepository>(),
                listId: listId,
              )..add(LoadListDetailsEvent()),
          child: const ListDetailsScreen(),
        );
      },
    ),
    GoRoute(
      path: '/nova-lista',
      builder: (context, state) {
        final listasBloc = state.extra as ListasBloc;
        return BlocProvider.value(value: listasBloc, child: NovaListaScreen());
      },
    ),
    GoRoute(
      path: '/join-list',
      builder: (context, state) {
        final listasBloc = state.extra as ListasBloc;
        return BlocProvider.value(value: listasBloc, child: JoinListScreen());
      },
    ),
    GoRoute(
      path: '/join/:listId',
      redirect: (context, state) async {
        final listId = state.pathParameters['listId']!;
        try {
          await sl<ListasRepository>().joinList(listId);
          return '/list/$listId';
        } catch (e) {
          debugPrint('Erro ao entrar na lista: $e');
          return '/home';
        }
      },
      builder:
          (context, state) =>
              const Scaffold(body: Center(child: Text('Carregando...'))),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Comprinhas',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
