import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  static const _specialEffectsKey = 'special_effects_enabled';
  static const _developerModeKey = 'developer_mode_enabled';

  final ValueNotifier<bool> specialEffectsEnabled = ValueNotifier(true);
  final ValueNotifier<bool> developerModeEnabled = ValueNotifier(false);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    specialEffectsEnabled.value = prefs.getBool(_specialEffectsKey) ?? true;
    developerModeEnabled.value = prefs.getBool(_developerModeKey) ?? false;
  }

  Future<void> setSpecialEffectsEnabled(bool enabled) async {
    if (specialEffectsEnabled.value == enabled) return;

    specialEffectsEnabled.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_specialEffectsKey, enabled);
  }

  Future<void> setDeveloperModeEnabled(bool enabled) async {
    if (developerModeEnabled.value == enabled) return;

    developerModeEnabled.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_developerModeKey, enabled);
  }
}
