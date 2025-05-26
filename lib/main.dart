import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/auth/presentation/screens/login_screen.dart';
import 'package:flutter_comprinhas/auth/presentation/screens/splash_screen.dart';
import 'package:flutter_comprinhas/home/presentation/screens/home_screen.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/nova_lista_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comprinhas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => HomeScreen(),
        '/listas/nova_lista': (context) => NovaListaScreen(),
        '/login': (context) => LoginScreen(),
      },
    );
  }
}
