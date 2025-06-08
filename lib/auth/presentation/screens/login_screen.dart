import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/main.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signIn(BuildContext context) async {
    final googleSignIn = GoogleSignIn(
      serverClientId: dotenv.get('GCLOUD_WEB_CLIENT_ID'),
    );
    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser!.authentication;

    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null) {
      throw 'Access token não encontrado';
    }
    if (idToken == null) {
      throw 'ID token não encontrado';
    }
    final response = await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      accessToken: accessToken,
      idToken: idToken,
    );

    if (response.user != null) {
      debugPrint("logado como ${response.user!.email}");

      if (context.mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Bem-vindo!"),
            ElevatedButton.icon(
              onPressed: () => _signIn(context),
              icon: const Icon(Icons.login),
              label: const Text("Entrar com Google"),
            ),
          ],
        ),
      ),
    );
  }
}
