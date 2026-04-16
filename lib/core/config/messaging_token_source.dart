import 'package:firebase_messaging/firebase_messaging.dart';

abstract class MessagingTokenSource {
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
}

class FirebaseMessagingTokenSource implements MessagingTokenSource {
  @override
  Future<String?> getToken() {
    return FirebaseMessaging.instance.getToken();
  }

  @override
  Stream<String> get onTokenRefresh {
    return FirebaseMessaging.instance.onTokenRefresh;
  }
}
