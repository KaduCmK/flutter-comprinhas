import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MercadoDetailsMapCard extends StatelessWidget {
  final String? endereco;
  final LatLng? coordinates;
  final bool isLoadingCoords;
  final bool isMapInteractive;
  final VoidCallback onOpenRoute;
  final VoidCallback onEnableMapInteraction;
  final VoidCallback onDisableMapInteraction;

  const MercadoDetailsMapCard({
    super.key,
    required this.endereco,
    required this.coordinates,
    required this.isLoadingCoords,
    required this.isMapInteractive,
    required this.onOpenRoute,
    required this.onEnableMapInteraction,
    required this.onDisableMapInteraction,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Como chegar',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        endereco?.isNotEmpty == true
                            ? endereco!
                            : 'Endereço não registrado para este mercado.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed:
                      coordinates != null && !isLoadingCoords
                          ? onOpenRoute
                          : null,
                  icon: const Icon(Icons.alt_route),
                  label: const Text('Rota'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 240,
                child: Stack(
                  children: [
                    IgnorePointer(
                      ignoring: !isMapInteractive,
                      child: FlutterMap(
                        key: ValueKey(
                          '${coordinates?.latitude}-${coordinates?.longitude}',
                        ),
                        options: MapOptions(
                          initialCenter:
                              coordinates ?? const LatLng(-22.9068, -43.1729),
                          initialZoom: coordinates != null ? 15.0 : 13.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'io.github.kaducmk.comprinhas',
                          ),
                          if (coordinates != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: coordinates!,
                                  width: 80,
                                  height: 80,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (isLoadingCoords)
                      Container(
                        color: Colors.black12,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    if (!isLoadingCoords &&
                        coordinates == null &&
                        endereco != null &&
                        endereco!.isNotEmpty)
                      _MapOverlayMessage(
                        message:
                            'Não foi possível localizar o endereço no mapa.',
                      ),
                    if (endereco == null || endereco!.isEmpty)
                      const _MapOverlayMessage(
                        message: 'Mapa indisponível sem endereço.',
                      ),
                    if (!isLoadingCoords &&
                        coordinates != null &&
                        !isMapInteractive)
                      Positioned.fill(
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.16),
                          child: InkWell(
                            onTap: onEnableMapInteraction,
                            child: Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface.withValues(
                                    alpha: 0.96,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.touch_app,
                                      color: colorScheme.primary,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Toque para interagir com o mapa',
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Enquanto bloqueado, o scroll da tela funciona sem arrastar o mapa.',
                                      textAlign: TextAlign.center,
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (isMapInteractive)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: FilledButton.tonalIcon(
                          onPressed: onDisableMapInteraction,
                          icon: const Icon(Icons.lock_outline),
                          label: const Text('Bloquear mapa'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapOverlayMessage extends StatelessWidget {
  final String message;

  const _MapOverlayMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black45,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
