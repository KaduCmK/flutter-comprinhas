import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/core/config/app_settings_service.dart';
import 'package:flutter_comprinhas/core/config/service_locator.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_repository.dart';
import 'package:flutter_comprinhas/mercado/presentation/components/shiny_tilt_card.dart';
import 'package:flutter_comprinhas/shared/entities/mercado.dart';

class MercadoDetailsHeroCard extends StatelessWidget {
  final Mercado mercado;
  final MercadoStats stats;
  final int productsCount;

  const MercadoDetailsHeroCard({
    super.key,
    required this.mercado,
    required this.stats,
    required this.productsCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder<bool>(
      valueListenable: sl<AppSettingsService>().specialEffectsEnabled,
      builder: (context, effectsEnabled, _) {
        return ShinyTiltCard(
          effectsEnabled: effectsEnabled,
          borderRadius: BorderRadius.circular(28),
          baseColors: [
            colorScheme.primaryContainer,
            colorScheme.surfaceContainerHighest,
          ],
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          mercado.nome.isNotEmpty
                              ? mercado.nome[0].toUpperCase()
                              : 'M',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mercado.nome,
                            style: textTheme.headlineSmall?.copyWith(
                              fontSize: 25,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onPrimaryContainer,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (mercado.cnpj != null &&
                              mercado.cnpj!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surface.withValues(
                                  alpha: 0.65,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'CNPJ ${mercado.cnpj}',
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Gasto total',
                        value:
                            'R\$ ${stats.valorTotalGasto.toStringAsFixed(2)}',
                        icon: Icons.payments_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricTile(
                        label: 'Notas',
                        value: stats.totalNotas.toString(),
                        icon: Icons.receipt_long,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricTile(
                        label: 'Produtos',
                        value: productsCount.toString(),
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
