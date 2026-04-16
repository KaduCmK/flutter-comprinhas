import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_comprinhas/core/config/messaging_token_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushTokenSyncService {
  final SupabaseClient _client;
  final MessagingTokenSource _messagingTokenSource;

  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _lastSyncedToken;
  bool _started = false;

  PushTokenSyncService({
    required SupabaseClient client,
    required MessagingTokenSource messagingTokenSource,
  }) : _client = client,
       _messagingTokenSource = messagingTokenSource;

  Future<void> start() async {
    if (_started) return;

    _started = true;
    await _syncCurrentToken();

    _tokenRefreshSubscription = _messagingTokenSource.onTokenRefresh.listen(
      (token) {
        unawaited(_syncToken(token));
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Erro ao observar refresh do token FCM: $error');
      },
    );
  }

  Future<void> _syncCurrentToken() async {
    try {
      final token = await _messagingTokenSource.getToken();
      await _syncToken(token);
    } catch (e) {
      debugPrint('Erro ao sincronizar token FCM atual: $e');
    }
  }

  Future<void> _syncToken(String? token) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || token == null || token.isEmpty) return;
    if (_lastSyncedToken == token) return;

    try {
      await _client.from('users').update({'fcm_token': token}).eq('id', userId);
      _lastSyncedToken = token;
    } catch (e) {
      debugPrint('Erro ao persistir token FCM: $e');
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _started = false;
    _lastSyncedToken = null;
  }
}
