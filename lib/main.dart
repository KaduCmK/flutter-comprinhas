import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Supabase.initialize(
    url: 'https://dvjsrjuhslwtwhgceymg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2anNyanVoc2x3dHdoZ2NleW1nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgxMTIxMDksImV4cCI6MjA2MzY4ODEwOX0.iP_Rz7-jR-NZvz8mFdVNCYoRtKyXtz3-FTLMrYt3DGc'
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
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Scaffold()
    );
  }
}
