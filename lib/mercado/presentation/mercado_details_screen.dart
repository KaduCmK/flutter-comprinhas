import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/core/config/service_locator.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_geocoding_service.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_navigation_service.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_repository.dart';
import 'package:flutter_comprinhas/mercado/presentation/components/mercado_details_hero_card.dart';
import 'package:flutter_comprinhas/mercado/presentation/components/mercado_details_map_card.dart';
import 'package:flutter_comprinhas/mercado/presentation/components/mercado_details_notes_section.dart';
import 'package:flutter_comprinhas/mercado/presentation/components/mercado_details_products_section.dart';
import 'package:flutter_comprinhas/shared/entities/purchase_history.dart';
import 'package:latlong2/latlong.dart';

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
  final MercadoGeocodingService _geocodingService =
      sl<MercadoGeocodingService>();
  final MercadoNavigationService _navigationService =
      sl<MercadoNavigationService>();

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

    setState(() => _isLoadingCoords = true);

    final coordinates = await _geocodingService.fetchCoordinates(endereco);
    if (!mounted) return;

    setState(() {
      _coordinates = coordinates;
      _isLoadingCoords = false;
    });
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

    final launched = await _navigationService.openRoute(
      coordinates: coordinates,
      mercadoNome: widget.stats.mercado.nome,
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
                    MercadoDetailsHeroCard(
                      mercado: mercado,
                      stats: widget.stats,
                      productsCount: _products.length,
                    ),
                    const SizedBox(height: 16),
                    MercadoDetailsMapCard(
                      endereco: mercado.endereco,
                      coordinates: _coordinates,
                      isLoadingCoords: _isLoadingCoords,
                      isMapInteractive: _isMapInteractive,
                      onOpenRoute: _openRoute,
                      onEnableMapInteraction:
                          () => setState(() => _isMapInteractive = true),
                      onDisableMapInteraction:
                          () => setState(() => _isMapInteractive = false),
                    ),
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
              ? MercadoDetailsProductsSection(
                searchController: _searchController,
                products: _products,
                filteredProducts: _filteredProducts,
              )
              : MercadoDetailsNotesSection(marketHistory: _marketHistory),
    );
  }
}
