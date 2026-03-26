import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_repository.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class MercadoDetailsScreen extends StatefulWidget {
  final MercadoStats stats;

  const MercadoDetailsScreen({super.key, required this.stats});

  @override
  State<MercadoDetailsScreen> createState() => _MercadoDetailsScreenState();
}

class _MercadoDetailsScreenState extends State<MercadoDetailsScreen> {
  LatLng? _coordinates;
  bool _isLoadingCoords = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchCoordinates();
  }

  Future<void> _fetchCoordinates() async {
    final endereco = widget.stats.mercado.endereco;
    if (endereco == null || endereco.isEmpty) return;

    setState(() {
      _isLoadingCoords = true;
    });

    try {
      // Usando Nominatim do OpenStreetMap para geocodificação gratuita
      final encodedAddress = Uri.encodeComponent(endereco);
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$encodedAddress&format=json&limit=1');

      final response = await http.get(url, headers: {
        'User-Agent': 'io.github.kaducmk.comprinhas',
      });

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          setState(() {
            _coordinates = LatLng(lat, lon);
          });
          // Move o mapa para a nova posição
          _mapController.move(_coordinates!, 15.0);
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar coordenadas: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCoords = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mercado = widget.stats.mercado;
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
                        "R\$ ${widget.stats.valorTotalGasto.toStringAsFixed(2)}",
                        "Gasto Total",
                      ),
                      Container(width: 1, height: 40, color: colorScheme.outlineVariant),
                      _buildStatColumn(
                        context,
                        widget.stats.totalNotas.toString(),
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
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: const MapOptions(
                            initialCenter: LatLng(-22.9068, -43.1729), // Fallback inicial (RJ)
                            initialZoom: 13.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'io.github.kaducmk.comprinhas',
                            ),
                            if (_coordinates != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _coordinates!,
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
                        if (_isLoadingCoords)
                          Container(
                            color: Colors.black12,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                        if (!_isLoadingCoords && _coordinates == null && mercado.endereco != null)
                          Container(
                            color: Colors.black45,
                            padding: const EdgeInsets.all(16),
                            child: const Center(
                              child: Text(
                                "Não foi possível localizar o endereço no mapa",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
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
