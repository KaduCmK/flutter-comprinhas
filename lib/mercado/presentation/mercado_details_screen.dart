import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/core/config/app_settings_service.dart';
import 'package:flutter_comprinhas/core/config/service_locator.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_repository.dart';
import 'package:flutter_comprinhas/shared/entities/purchase_history.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum MercadoDetailsSection { products, notes }

class MercadoDetailsScreen extends StatefulWidget {
  final MercadoStats stats;

  const MercadoDetailsScreen({super.key, required this.stats});

  @override
  State<MercadoDetailsScreen> createState() => _MercadoDetailsScreenState();
}

class _MercadoDetailsScreenState extends State<MercadoDetailsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MercadoRepository _repository = sl<MercadoRepository>();

  LatLng? _coordinates;
  bool _isLoadingCoords = false;
  bool _isLoadingContent = true;
  bool _isMapInteractive = false;
  String? _contentError;

  MercadoDetailsSection _selectedSection = MercadoDetailsSection.products;
  List<MercadoProdutoResumo> _products = [];
  List<PurchaseHistory> _marketHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchCoordinates();
    _loadContent();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoadingContent = true;
      _contentError = null;
    });

    try {
      final mercadoId = widget.stats.mercado.id;
      final results = await Future.wait([
        _repository.getProductsByMercado(mercadoId),
        _repository.getNfeHistoryByMercado(mercadoId),
      ]);

      if (!mounted) return;

      setState(() {
        _products = results[0] as List<MercadoProdutoResumo>;
        _marketHistory = results[1] as List<PurchaseHistory>;
        _isLoadingContent = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _contentError = 'Erro ao carregar detalhes do mercado: $e';
        _isLoadingContent = false;
      });
    }
  }

  Future<void> _fetchCoordinates() async {
    final endereco = widget.stats.mercado.endereco;
    if (endereco == null || endereco.isEmpty) return;

    setState(() {
      _isLoadingCoords = true;
    });

    try {
      final encodedAddress = Uri.encodeComponent(endereco);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encodedAddress&format=json&limit=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'io.github.kaducmk.comprinhas'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final coordinates = LatLng(lat, lon);

          if (!mounted) return;

          setState(() {
            _coordinates = coordinates;
          });
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

  Future<void> _openRoute() async {
    final coordinates = _coordinates;
    if (coordinates == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A rota ficará disponível quando o endereço for localizado.',
          ),
        ),
      );
      return;
    }

    final mercadoNome = Uri.encodeComponent(widget.stats.mercado.nome);
    final routeUri = Uri.parse(
      'geo:${coordinates.latitude},${coordinates.longitude}?q=${coordinates.latitude},${coordinates.longitude}($mercadoNome)',
    );

    final launched = await launchUrl(
      routeUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir um aplicativo de mapas neste dispositivo.',
          ),
        ),
      );
    }
  }

  List<MercadoProdutoResumo> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _products;

    return _products
        .where((product) => product.nome.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final mercado = widget.stats.mercado;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('Detalhes do Mercado'), elevation: 0),
      body: RefreshIndicator(
        onRefresh: _loadContent,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    _buildHeroCard(context, mercado, textTheme, colorScheme),
                    const SizedBox(height: 16),
                    _buildMapCard(context, mercado, textTheme, colorScheme),
                    const SizedBox(height: 16),
                    _buildSectionSwitcher(context),
                    const SizedBox(height: 16),
                    _buildBody(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    dynamic mercado,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
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
                      child: _buildMetricTile(
                        context,
                        label: 'Gasto total',
                        value:
                            'R\$ ${widget.stats.valorTotalGasto.toStringAsFixed(2)}',
                        icon: Icons.payments_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        label: 'Notas',
                        value: widget.stats.totalNotas.toString(),
                        icon: Icons.receipt_long,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        label: 'Produtos',
                        value: _products.length.toString(),
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

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
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

  Widget _buildMapCard(
    BuildContext context,
    dynamic mercado,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
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
                        mercado.endereco?.isNotEmpty == true
                            ? mercado.endereco!
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
                      _coordinates != null && !_isLoadingCoords
                          ? _openRoute
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
                      ignoring: !_isMapInteractive,
                      child: FlutterMap(
                        key: ValueKey(
                          '${_coordinates?.latitude}-${_coordinates?.longitude}',
                        ),
                        options: MapOptions(
                          initialCenter:
                              _coordinates ?? const LatLng(-22.9068, -43.1729),
                          initialZoom: _coordinates != null ? 15.0 : 13.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'io.github.kaducmk.comprinhas',
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
                    ),
                    if (_isLoadingCoords)
                      Container(
                        color: Colors.black12,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    if (!_isLoadingCoords &&
                        _coordinates == null &&
                        mercado.endereco != null &&
                        mercado.endereco!.isNotEmpty)
                      _buildMapOverlayMessage(
                        context,
                        'Não foi possível localizar o endereço no mapa.',
                      ),
                    if (mercado.endereco == null || mercado.endereco!.isEmpty)
                      _buildMapOverlayMessage(
                        context,
                        'Mapa indisponível sem endereço.',
                      ),
                    if (!_isLoadingCoords &&
                        _coordinates != null &&
                        !_isMapInteractive)
                      Positioned.fill(
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.16),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isMapInteractive = true;
                              });
                            },
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
                    if (_isMapInteractive)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: FilledButton.tonalIcon(
                          onPressed: () {
                            setState(() {
                              _isMapInteractive = false;
                            });
                          },
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

  Widget _buildMapOverlayMessage(BuildContext context, String message) {
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

  Widget _buildSectionSwitcher(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SegmentedButton<MercadoDetailsSection>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment<MercadoDetailsSection>(
            value: MercadoDetailsSection.products,
            icon: Icon(Icons.inventory_2_outlined),
            label: Text('Produtos'),
          ),
          ButtonSegment<MercadoDetailsSection>(
            value: MercadoDetailsSection.notes,
            icon: Icon(Icons.receipt_long),
            label: Text('Notas'),
          ),
        ],
        selected: {_selectedSection},
        onSelectionChanged: (selection) {
          setState(() {
            _selectedSection = selection.first;
          });
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoadingContent) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_contentError != null) {
      final colorScheme = Theme.of(context).colorScheme;
      return Card(
        color: colorScheme.errorContainer,
        child: ListTile(
          leading: Icon(
            Icons.error_outline,
            color: colorScheme.onErrorContainer,
          ),
          title: Text(
            'Falha ao carregar detalhes',
            style: TextStyle(
              color: colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            _contentError!,
            style: TextStyle(color: colorScheme.onErrorContainer),
          ),
          trailing: IconButton(
            onPressed: _loadContent,
            icon: Icon(Icons.refresh, color: colorScheme.onErrorContainer),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child:
          _selectedSection == MercadoDetailsSection.products
              ? _buildProductsSection(context)
              : _buildHistorySection(context),
    );
  }

  Widget _buildProductsSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final filteredProducts = _filteredProducts;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      key: const ValueKey('products'),
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
            Text(
              'Produtos catalogados',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Veja o último preço conhecido de cada produto já capturado nas NF-es deste mercado.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar produto por nome',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_products.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Nenhum produto catalogado para este mercado ainda.',
                ),
              )
            else if (filteredProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Nenhum produto encontrado para o termo pesquisado.',
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredProducts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      title: Text(
                        product.nome,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Último registro em ${dateFormat.format(product.ultimaDataRegistro)}',
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'R\$ ${product.ultimoPreco.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'último preço',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      key: const ValueKey('notes'),
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
            Text(
              'Notas deste mercado',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Abra qualquer nota para ver os itens e seguir a navegação já existente do app.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            if (_marketHistory.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Nenhuma nota encontrada para este mercado.'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _marketHistory.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final purchase = _marketHistory[index];
                  final purchaseDate =
                      purchase.dataEmissao ?? purchase.confirmedAt;

                  return Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap:
                          () => context.push('/nfe-details', extra: purchase),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.receipt_long,
                                color: colorScheme.onTertiaryContainer,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateFormat.format(purchaseDate),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${purchase.items.length} itens',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'R\$ ${purchase.valorTotal.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Icon(
                                  Icons.arrow_outward,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class ShinyTiltCard extends StatefulWidget {
  final bool effectsEnabled;
  final Widget child;
  final BorderRadius borderRadius;
  final List<Color> baseColors;

  const ShinyTiltCard({
    super.key,
    required this.effectsEnabled,
    required this.child,
    required this.borderRadius,
    required this.baseColors,
  });

  @override
  State<ShinyTiltCard> createState() => _ShinyTiltCardState();
}

class _ShinyTiltCardState extends State<ShinyTiltCard> {
  static const double _gradientMotionMultiplier = 1.45;

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  Offset _gradientOffset = Offset.zero;
  bool _hasSensorEvent = false;
  double _debugX = 0;
  double _debugY = 0;

  @override
  void initState() {
    super.initState();
    if (widget.effectsEnabled) {
      _startEffects();
    }
  }

  @override
  void didUpdateWidget(covariant ShinyTiltCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.effectsEnabled == widget.effectsEnabled) return;

    if (widget.effectsEnabled) {
      _startEffects();
    } else {
      _stopEffects(reset: true);
    }
  }

  void _startEffects() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (!mounted) return;

      final normalizedX = (event.x / 9.8).clamp(-1.0, 1.0);
      final normalizedY = ((event.y / 9.8) - 0.77).clamp(-1.0, 1.0);
      final diagonalX = ((normalizedX * 1.2) + (normalizedY * 0.08)).clamp(
        -1.0,
        1.0,
      );
      final diagonalY = ((normalizedY * 0.35) - (normalizedX * 0.10)).clamp(
        -1.0,
        1.0,
      );
      final targetOffset = Offset(
        diagonalX * 138 * _gradientMotionMultiplier,
        diagonalY * 138 * _gradientMotionMultiplier,
      );

      setState(() {
        _hasSensorEvent = true;
        _debugX = normalizedX;
        _debugY = normalizedY;
        _gradientOffset = Offset(
          lerpDouble(_gradientOffset.dx, targetOffset.dx, 0.35)!,
          lerpDouble(_gradientOffset.dy, targetOffset.dy, 0.35)!,
        );
      });
    });
  }

  void _stopEffects({required bool reset}) {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;

    if (reset && mounted) {
      setState(() {
        _hasSensorEvent = false;
        _debugX = 0;
        _debugY = 0;
        _gradientOffset = Offset.zero;
      });
    }
  }

  @override
  void dispose() {
    _stopEffects(reset: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final developerModeEnabled = sl<AppSettingsService>().developerModeEnabled;

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SlidingGradientPainter(
                offset: _gradientOffset,
                colors: widget.baseColors,
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: developerModeEnabled,
            builder: (context, enabled, _) {
              if (!enabled) return const SizedBox.shrink();

              return Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _hasSensorEvent
                        ? 'x ${_debugX.toStringAsFixed(2)} | y ${_debugY.toStringAsFixed(2)}'
                        : 'sem sensor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _SlidingGradientPainter extends CustomPainter {
  final Offset offset;
  final List<Color> colors;

  const _SlidingGradientPainter({required this.offset, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final baseRect = Rect.fromCenter(
      center: Offset(size.width / 2 + offset.dx, size.height / 2 + offset.dy),
      width: size.width * 1.08,
      height: size.height * 1.08,
    );

    final basePaint =
        Paint()
          ..shader = LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(baseRect);

    canvas.drawRect(Offset.zero & size, basePaint);

    final shineRect = Rect.fromCenter(
      center: Offset(
        size.width / 2 + offset.dx * 1.15,
        size.height / 2 + offset.dy * 1.15,
      ),
      width: size.width * 1.18,
      height: size.height * 1.18,
    );

    final shinePaint =
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.28, 0.5, 0.72, 1.0],
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.16),
              Colors.white.withValues(alpha: 0.0),
              Colors.transparent,
            ],
          ).createShader(shineRect);

    canvas.drawRect(Offset.zero & size, shinePaint);
  }

  @override
  bool shouldRepaint(covariant _SlidingGradientPainter oldDelegate) {
    return oldDelegate.offset != offset || oldDelegate.colors != colors;
  }
}
