import 'package:flutter_comprinhas/core/platform/platform_capabilities.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

abstract class MessagingTokenSource {
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
}

class FirebaseMessagingTokenSource implements MessagingTokenSource {
  @override
  Future<String?> getToken() {
    if (!PlatformCapabilities.supportsFirebaseMessaging) {
      return Future.value(null);
    }

    return FirebaseMessaging.instance.getToken();
  }

  @override
  Stream<String> get onTokenRefresh {
    if (!PlatformCapabilities.supportsFirebaseMessaging) {
      return const Stream.empty();
    }

    return FirebaseMessaging.instance.onTokenRefresh;
  }
}
