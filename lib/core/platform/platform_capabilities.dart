import 'package:flutter/foundation.dart';

class PlatformCapabilities {
  static bool get isWeb => kIsWeb;

  static bool get supportsMercadoFeatures => !kIsWeb;

  static bool get supportsFirebaseMessaging => !kIsWeb;

  static bool get supportsLocalNotifications => !kIsWeb;

  static bool get supportsSpecialEffects => !kIsWeb;
}
