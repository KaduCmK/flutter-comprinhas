import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/core/platform/platform_capabilities.dart';
import 'package:flutter_comprinhas/core/config/push_token_sync_service.dart';
import 'package:flutter_comprinhas/core/config/service_locator.dart';
import 'package:flutter_comprinhas/main.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  final String? nextPath;

  const LoginScreen({super.key, this.nextPath});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirectIfLoggedIn());
  }

  Future<void> _redirectIfLoggedIn() async {
    if (!mounted) return;
    if (supabase.auth.currentSession == null) return;

    await sl<PushTokenSyncService>().start();
    if (!mounted) return;
    context.go(widget.nextPath ?? '/home');
  }

  Future<void> _signIn(BuildContext context) async {
    if (PlatformCapabilities.isWeb) {
      final redirectUri = Uri.parse(
        '${Uri.base.origin}/login${widget.nextPath != null ? '?next=${Uri.encodeComponent(widget.nextPath!)}' : ''}',
      );

      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUri.toString(),
      );
      return;
    }

    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize(
      serverClientId: dotenv.get('GCLOUD_WEB_CLIENT_ID'),
    );

    final googleUser = await googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;

    // final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    // if (accessToken == null) {
    //   throw 'Access token não encontrado';
    // }
    if (idToken == null) {
      throw 'ID token não encontrado';
    }
    final response = await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );

    if (response.user != null) {
      debugPrint("logado como ${response.user!.email}");
      await sl<PushTokenSyncService>().start();

      if (context.mounted) {
        context.go(widget.nextPath ?? '/home');
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
