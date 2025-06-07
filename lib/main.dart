import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/app_theme.dart';
import 'package:flutter_comprinhas/auth/presentation/screens/login_screen.dart';
import 'package:flutter_comprinhas/auth/presentation/screens/splash_screen.dart';
import 'package:flutter_comprinhas/core/config/firebase_config.dart';
import 'package:flutter_comprinhas/core/config/service_locator.dart';
import 'package:flutter_comprinhas/home/presentation/screens/home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comprinhas',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => HomeScreenProvider(),
        '/login': (context) => LoginScreen(),
      },
    );
  }
}
