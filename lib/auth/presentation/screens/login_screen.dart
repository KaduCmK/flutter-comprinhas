import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/main.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signIn() async {
    final googleSignIn = GoogleSignIn();
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

    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      accessToken: accessToken,
      idToken: idToken,
    );
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
              onPressed: () => _signIn(),
              icon: const Icon(Icons.login),
              label: const Text("Entrar com Google"),
            ),
          ],
        ),
      ),
    );
  }
}
