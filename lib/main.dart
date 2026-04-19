import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/app_theme.dart';
import 'package:flutter_comprinhas/auth/presentation/screens/login_screen.dart';
import 'package:flutter_comprinhas/auth/presentation/screens/splash_screen.dart';
import 'package:flutter_comprinhas/core/config/app_settings_service.dart';
import 'package:flutter_comprinhas/core/config/crash_reporting_service.dart';
import 'package:flutter_comprinhas/core/config/firebase_config.dart';
import 'package:flutter_comprinhas/core/config/notification_service.dart';
import 'package:flutter_comprinhas/core/config/service_locator.dart';
import 'package:flutter_comprinhas/core/platform/platform_capabilities.dart';
import 'package:flutter_comprinhas/global_cart/presentation/bloc/global_cart_bloc.dart';
import 'package:flutter_comprinhas/global_cart/presentation/global_cart_screen.dart';
import 'package:flutter_comprinhas/home/presentation/screens/home_screen.dart';
import 'package:flutter_comprinhas/home/presentation/screens/settings_screen.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/cart/cart_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/close_purchase_with_nfe/close_purchase_with_nfe_cubit.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/history/history_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details/list_details_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/close_purchase_with_nfe_screen.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/list_details_screen.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/list_history_screen.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/list_info_screen.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/bloc/listas_bloc.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/join_link_screen.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/join_list_screen.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/nova_lista_screen.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_repository.dart';
import 'package:flutter_comprinhas/mercado/presentation/bloc/nfe_details_cubit.dart';
import 'package:flutter_comprinhas/mercado/presentation/bloc/mercado_bloc.dart';
import 'package:flutter_comprinhas/mercado/presentation/enviar_nota_screen.dart';
import 'package:flutter_comprinhas/mercado/presentation/mercado_details_screen.dart';
import 'package:flutter_comprinhas/mercado/presentation/nfe_details_screen.dart';
import 'package:flutter_comprinhas/shared/entities/purchase_history.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('pt_BR', null);
    await dotenv.load(fileName: '.env');

    configureServiceLocator();
    await sl<AppSettingsService>().init();
    await sl<NotificationService>().init();

    await configureFirebase();
    await CrashReportingService.init();

    await Supabase.initialize(
      url: dotenv.get('SUPABASE_URL'),
      anonKey: dotenv.get('SUPABASE_ANON_KEY'),
    );

    runApp(const MyApp());
  }, (error, stackTrace) async {
    FlutterError.presentError(
      FlutterErrorDetails(exception: error, stack: stackTrace),
    );
    await CrashReportingService.recordError(
      error,
      stackTrace,
      fatal: true,
      reason: 'Erro não tratado em runZonedGuarded',
    );
  });
}

final supabase = Supabase.instance.client;

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/login',
      builder:
          (context, state) =>
              LoginScreen(nextPath: state.uri.queryParameters['next']),
    ),
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
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
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
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create:
                  (context) => CartBloc(
                    repository: sl<ListasRepository>(),
                    client: supabase,
                    listId: listId,
                  )..add(LoadCart()),
            ),
            BlocProvider(
              create:
                  (context) => ListDetailsBloc(
                    repository: sl<ListasRepository>(),
                    client: supabase,
                    listId: listId,
                    cartBloc: context.read<CartBloc>(),
                  )..add(LoadListDetails()),
            ),
          ],
          child: const ListDetailsScreen(),
        );
      },
    ),
    GoRoute(
      path: '/list/:listId/history',
      builder: (context, state) {
        final listId = state.pathParameters['listId']!;
        return BlocProvider(
          create:
              (context) => HistoryBloc(
                repository: sl<ListasRepository>(),
                listId: listId,
              )..add(LoadHistory()),
          child: ListHistoryScreen(listId: listId),
        );
      },
    ),
    GoRoute(
      path: '/list/:listId/close-with-nf',
      builder: (context, state) {
        final cartBloc = state.extra as CartBloc;
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cartBloc),
            BlocProvider(
              create:
                  (_) => ClosePurchaseWithNfeCubit(
                    repository: sl<ListasRepository>(),
                    cartItemIdsResolver:
                        () => _resolveClosePurchaseCartItemIds(cartBloc),
                    onPurchaseConfirmed: () => cartBloc.add(LoadCart()),
                  ),
            ),
          ],
          child: const ClosePurchaseWithNfeScreen(),
        );
      },
    ),
    GoRoute(
      path: '/list/:listId/info',
      builder: (context, state) {
        return BlocProvider(
          create:
              (_) =>
                  ListasBloc(repository: sl<ListasRepository>())
                    ..add(GetListsEvent()),
          child: ListInfoScreen(listId: state.pathParameters['listId']!),
        );
      },
    ),
    GoRoute(
      path: '/listas/nova',
      builder: (context, state) {
        return BlocProvider(
          create:
              (_) =>
                  ListasBloc(repository: sl<ListasRepository>())
                    ..add(GetListsEvent()),
          child: const NovaListaScreen(),
        );
      },
    ),
    GoRoute(
      path: '/listas/:listId/editar',
      builder: (context, state) {
        return BlocProvider(
          create:
              (_) =>
                  ListasBloc(repository: sl<ListasRepository>())
                    ..add(GetListsEvent()),
          child: NovaListaScreen(listId: state.pathParameters['listId']!),
        );
      },
    ),
    GoRoute(
      path: '/join-list',
      builder: (context, state) => const JoinListScreen(),
    ),
    GoRoute(
      path: '/join/:listId',
      builder:
          (context, state) =>
              JoinLinkScreen(encodedListId: state.pathParameters['listId']!),
    ),
    GoRoute(
      path: '/enviar-nfe',
      builder: (context, state) {
        if (!PlatformCapabilities.supportsMercadoFeatures) {
          return const _UnsupportedFeatureScreen(
            title: 'Mercados indisponível',
            message: 'O fluxo de nota fiscal ainda não está disponível na web.',
          );
        }

        final extra = state.extra;
        if (extra is MercadoBloc) {
          return BlocProvider.value(
            value: extra,
            child: const EnviarNotaScreen(),
          );
        }
        return const EnviarNotaScreen(returnAccessKey: true);
      },
    ),
    GoRoute(
      path: '/nfe-details',
      builder: (context, state) {
        if (!PlatformCapabilities.supportsMercadoFeatures) {
          return const _UnsupportedFeatureScreen(
            title: 'Mercados indisponível',
            message: 'Esta área ainda não está disponível na web.',
          );
        }

        final purchase = state.extra as PurchaseHistory;
        return BlocProvider(
          create: (_) => NfeDetailsCubit(mercadoRepository: sl()),
          child: NfeDetailsScreen(purchase: purchase),
        );
      },
    ),
    GoRoute(
      path: '/mercado-details',
      builder: (context, state) {
        if (!PlatformCapabilities.supportsMercadoFeatures) {
          return const _UnsupportedFeatureScreen(
            title: 'Mercados indisponível',
            message: 'Esta área ainda não está disponível na web.',
          );
        }

        final stats = state.extra as MercadoStats;
        return MercadoDetailsScreen(stats: stats);
      },
    ),
  ],
);

List<String> _resolveClosePurchaseCartItemIds(CartBloc cartBloc) {
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  if (cartBloc.state.cartMode == CartMode.individual && currentUserId != null) {
    return cartBloc.state.cartItems
        .where((item) => item.user.id == currentUserId)
        .map((item) => item.id)
        .toList();
  }

  return cartBloc.state.cartItems.map((item) => item.id).toList();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          title: 'Comprinhas',
          theme: AppTheme.light(colorScheme: lightDynamic),
          darkTheme: AppTheme.dark(colorScheme: darkDynamic),
          themeMode: ThemeMode.system,
          routerConfig: _router,
        );
      },
    );
  }
}

class _UnsupportedFeatureScreen extends StatelessWidget {
  final String title;
  final String message;

  const _UnsupportedFeatureScreen({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
