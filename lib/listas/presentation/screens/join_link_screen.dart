import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/core/config/service_locator.dart';
import 'package:flutter_comprinhas/core/platform/deep_link_launcher.dart';
import 'package:flutter_comprinhas/listas/presentation/components/list_share_link.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JoinLinkScreen extends StatefulWidget {
  final String encodedListId;

  const JoinLinkScreen({super.key, required this.encodedListId});

  @override
  State<JoinLinkScreen> createState() => _JoinLinkScreenState();
}

class _JoinLinkScreenState extends State<JoinLinkScreen> {
  String? _errorMessage;
  bool _isResolving = true;
  bool _attemptedAppLaunch = false;

  @override
  void initState() {
    super.initState();
    unawaited(_tryOpenInstalledApp());
    unawaited(_resolveJoin());
  }

  Future<void> _tryOpenInstalledApp() async {
    if (_attemptedAppLaunch || !kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    _attemptedAppLaunch = true;
    await tryLaunchDeepLink(
      ListShareLink.buildAppDeepLinkFromEncodedId(widget.encodedListId),
    );
  }

  Future<void> _resolveJoin() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      final nextPath = Uri(
        path: '/join/${widget.encodedListId}',
      ).toString();
      if (mounted) {
        context.go('/login?next=${Uri.encodeComponent(nextPath)}');
      }
      return;
    }

    final decodedListId = _decodeListId(widget.encodedListId);
    if (decodedListId == null) {
      _setError('Link de convite inválido.');
      return;
    }

    final repository = sl<ListasRepository>();

    try {
      await repository.joinList(decodedListId);
      await repository.getListById(decodedListId);
      if (mounted) {
        context.go('/list/$decodedListId');
      }
      return;
    } catch (_) {
      try {
        await repository.getListById(decodedListId);
        if (mounted) {
          context.go('/list/$decodedListId');
        }
        return;
      } catch (_) {
        _setError('Não foi possível entrar na lista com este link.');
      }
    }
  }

  String? _decodeListId(String encodedListId) {
    try {
      return utf8.decode(base64Url.decode(encodedListId));
    } catch (_) {
      return null;
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isResolving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isResolving) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  kIsWeb &&
                          (defaultTargetPlatform == TargetPlatform.android ||
                              defaultTargetPlatform == TargetPlatform.iOS)
                      ? 'Tentando abrir no app e entrar na lista...'
                      : 'Entrando na lista...',
                  textAlign: TextAlign.center,
                ),
                if (kIsWeb &&
                    (defaultTargetPlatform == TargetPlatform.android ||
                        defaultTargetPlatform == TargetPlatform.iOS)) ...[
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed:
                        () => unawaited(
                          tryLaunchDeepLink(
                            ListShareLink.buildAppDeepLinkFromEncodedId(
                              widget.encodedListId,
                            ),
                          ),
                        ),
                    child: const Text('Abrir no app'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Entrar na lista')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage ?? 'Não foi possível abrir este convite.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Ir para a home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
