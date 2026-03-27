import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/core/config/app_settings_service.dart';
import 'package:flutter_comprinhas/core/config/service_locator.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = sl<AppSettingsService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ValueListenableBuilder<bool>(
              valueListenable: settings.specialEffectsEnabled,
              builder: (context, enabled, _) {
                return SwitchListTile(
                  value: enabled,
                  onChanged: settings.setSpecialEffectsEnabled,
                  title: const Text('Efeitos especiais'),
                  subtitle: const Text(
                    'Controla animações e efeitos visuais com sensor. Quando desligado, o app para de usar essa funcionalidade para economizar bateria.',
                  ),
                );
              },
            ),
          ),
          Card(
            child: ValueListenableBuilder<bool>(
              valueListenable: settings.developerModeEnabled,
              builder: (context, enabled, _) {
                return SwitchListTile(
                  value: enabled,
                  onChanged: settings.setDeveloperModeEnabled,
                  title: const Text('Modo Desenvolvedor'),
                  subtitle: const Text(
                    'Exibe indicadores e informações extras de diagnóstico na interface.',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
