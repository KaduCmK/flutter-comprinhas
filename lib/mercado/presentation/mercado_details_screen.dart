import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_repository.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MercadoDetailsScreen extends StatelessWidget {
  final MercadoStats stats;

  const MercadoDetailsScreen({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final mercado = stats.mercado;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Mercado'),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    child: Text(
                      mercado.nome.isNotEmpty ? mercado.nome[0].toUpperCase() : 'M',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    mercado.nome,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (mercado.cnpj != null && mercado.cnpj!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "CNPJ: ${mercado.cnpj}",
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn(
                        context,
                        "R\$ ${stats.valorTotalGasto.toStringAsFixed(2)}",
                        "Gasto Total",
                      ),
                      Container(width: 1, height: 40, color: colorScheme.outlineVariant),
                      _buildStatColumn(
                        context,
                        stats.totalNotas.toString(),
                        "Notas Fiscais",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Localização",
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (mercado.endereco != null && mercado.endereco!.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            mercado.endereco!,
                            style: textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    )
                  else
                    const Text("Endereço não registrado para este mercado."),
                  const SizedBox(height: 16),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    clipBehavior: Clip.antiAlias,
                    // TODO: A geocodificação real precisa das coordenadas.
                    // Estamos usando um fallback visual por enquanto.
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: const MapOptions(
                            initialCenter: LatLng(-22.9068, -43.1729), // RJ como Fallback
                            initialZoom: 13.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.flutter_comprinhas',
                            ),
                            if (mercado.endereco != null && mercado.endereco!.isNotEmpty)
                              const MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(-22.9068, -43.1729), // RJ como Fallback
                                    width: 80,
                                    height: 80,
                                    child: Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        // Overlay para indicar que é ilustrativo caso falte geocodificação
                        if (mercado.endereco == null || mercado.endereco!.isEmpty)
                          Container(
                            color: Colors.black45,
                            child: Center(
                              child: Text(
                                "Mapa indisponível sem endereço",
                                style: textTheme.titleMedium?.copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
              ),
        ),
      ],
    );
  }
}
