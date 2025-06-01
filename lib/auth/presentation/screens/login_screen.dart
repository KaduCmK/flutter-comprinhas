import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/main.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

      final fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint("fcm token: $fcmToken");
      final fcmResponse = await supabase.functions.invoke(
        'fcm-token',
        body: {'fcm_token': fcmToken},
      );
      if (fcmResponse.status == 200) {
        debugPrint("FCM token enviado com sucesso para a Edge Function.");
        debugPrint("Resposta da função: ${fcmResponse.data}");
      } else {
        debugPrint("Erro ao enviar FCM token para a Edge Function.");
        debugPrint("Status: ${fcmResponse.status}");
        debugPrint("Resposta: ${fcmResponse.data}");
      }

      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
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
