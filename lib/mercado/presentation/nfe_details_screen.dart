import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/core/config/service_locator.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_repository.dart';
import 'package:flutter_comprinhas/shared/entities/purchase_history.dart';
import 'package:flutter_comprinhas/shared/entities/purchase_history_item.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class NfeDetailsScreen extends StatefulWidget {
  final PurchaseHistory purchase;

  const NfeDetailsScreen({super.key, required this.purchase});

  @override
  State<NfeDetailsScreen> createState() => _NfeDetailsScreenState();
}

class _NfeDetailsScreenState extends State<NfeDetailsScreen> {
  bool _isNavigatingToMercado = false;

  Future<void> _goToMercadoDetails() async {
    if (widget.purchase.mercado == null) return;

    setState(() => _isNavigatingToMercado = true);

    try {
      final repo = sl<MercadoRepository>();
      final stats = await repo.getMercadoStatsById(widget.purchase.mercado!.id);
      
      if (mounted && stats != null) {
        context.push('/mercado-details', extra: stats);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados do mercado: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isNavigatingToMercado = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mercado = widget.purchase.mercado;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text("Nota Fiscal Eletrônica"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho da Nota (Simulando NF brasileira)
            InkWell(
              onTap: _goToMercadoDetails,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Text(
                          mercado?.nome.toUpperCase() ?? "MERCADO DESCONHECIDO",
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        if (mercado?.cnpj != null)
                          Text("CNPJ: ${mercado!.cnpj}", style: textTheme.bodySmall),
                        if (mercado?.endereco != null)
                          Text(
                            mercado!.endereco!,
                            style: textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        const Divider(height: 24),
                        const Text(
                          "Extrato de Nota Fiscal de Consumidor Eletrônica",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildNfInfo("DATA", DateFormat('dd/MM/yyyy HH:mm').format(widget.purchase.dataEmissao ?? widget.purchase.confirmedAt)),
                            _buildNfInfo("USUÁRIO", widget.purchase.confirmedBy?.toUpperCase() ?? "N/A"),
                          ],
                        ),
                      ],
                    ),
                    if (_isNavigatingToMercado)
                      const Positioned.fill(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (mercado != null)
                      const Positioned(
                        top: 0,
                        right: 0,
                        child: Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tabela de Itens
            const Text("DETALHE DOS ITENS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const Divider(thickness: 2),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(flex: 1, child: Text("CÓD", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  Expanded(flex: 4, child: Text("DESCRIÇÃO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text("QTD", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                  Expanded(flex: 1, child: Text("UN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text("VLR.UN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                  Expanded(flex: 2, child: Text("TOTAL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                ],
              ),
            ),
            const Divider(),
            
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.purchase.items.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 0),
              itemBuilder: (context, index) {
                final item = widget.purchase.items[index];
                final double unitPrice = item.amount > 0 ? (item.valorTotal / item.amount) : 0;

                String displayCode = "---";
                if (item.codigo != null && item.codigo!.isNotEmpty) {
                  displayCode = item.codigo!.length > 4 ? item.codigo!.substring(0, 4) : item.codigo!;
                }

                return InkWell(
                  onTap: item.produtoId != null ? () => _showPriceEvolution(context, item) : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(flex: 1, child: Text(displayCode, style: const TextStyle(fontSize: 10))),
                        Expanded(
                          flex: 4, 
                          child: Text(
                            item.name.toUpperCase(), 
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        ),
                        Expanded(flex: 1, child: Text(item.amount.toString(), style: const TextStyle(fontSize: 10), textAlign: TextAlign.right)),
                        Expanded(flex: 1, child: Text(item.unit?.abbreviation.toUpperCase() ?? "UN", style: const TextStyle(fontSize: 10), textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text(unitPrice.toStringAsFixed(2), style: const TextStyle(fontSize: 10), textAlign: TextAlign.right)),
                        Expanded(flex: 2, child: Text(item.valorTotal.toStringAsFixed(2), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(thickness: 2),
            
            // Totais
            const SizedBox(height: 16),
            _buildTotalRow("Qtd. total de itens", widget.purchase.items.length.toString()),
            _buildTotalRow("Valor total R\$", widget.purchase.valorTotal.toStringAsFixed(2), isBold: true, fontSize: 18),
            
            const SizedBox(height: 24),

            // Chave de Acesso (Movida para baixo dos itens)
            if (widget.purchase.chaveAcesso != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("CHAVE DE ACESSO", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      widget.purchase.chaveAcesso!.replaceAllMapped(RegExp(r".{4}"), (match) => "${match.group(0)} "),
                      style: const TextStyle(fontSize: 11, letterSpacing: 1),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),
            Center(
              child: Opacity(
                opacity: 0.5,
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_2, size: 100),
                    const SizedBox(height: 8),
                    Text("Consulta via QR Code ou Chave de Acesso", style: textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNfInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize)),
        ],
      ),
    );
  }

  void _showPriceEvolution(BuildContext context, PurchaseHistoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PriceEvolutionSheet(
        item: item,
        currentPurchaseDate: widget.purchase.dataEmissao ?? widget.purchase.confirmedAt,
      ),
    );
  }
}

class PriceEvolutionSheet extends StatefulWidget {
  final PurchaseHistoryItem item;
  final DateTime currentPurchaseDate;

  const PriceEvolutionSheet({
    super.key,
    required this.item,
    required this.currentPurchaseDate,
  });

  @override
  State<PriceEvolutionSheet> createState() => _PriceEvolutionSheetState();
}

class _PriceEvolutionSheetState extends State<PriceEvolutionSheet> {
  List<Map<String, dynamic>>? _history;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    sl<MercadoRepository>()
        .getProductPriceHistory(widget.item.produtoId!)
        .then((data) {
      if (mounted) {
        setState(() {
          _history = data;
          _loading = false;
        });
      }
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError(context)
                : _buildContent(context, scrollController, _history ?? []),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text("Erro ao carregar histórico", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text("$_error", textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar"),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
    List<Map<String, dynamic>> history,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.item.name.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(height: 32),
          const Text("Evolução de Preços", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text("Sem dados históricos.")),
            )
          else if (history.length < 2)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text("Histórico insuficiente para gerar gráfico.")),
            )
          else
            _buildChart(context, history, colorScheme),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar"),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<Map<String, dynamic>> history,
    ColorScheme colorScheme,
  ) {
    // Round to 2 decimals for calculations and display
    final cleanHistory = history.map((e) {
      final double rawPrice = e['preco_unitario'] as double;
      return {
        ...e,
        'preco_unitario': double.parse(rawPrice.toStringAsFixed(2)),
      };
    }).toList();

    final prices = cleanHistory
        .map((e) => e['preco_unitario'] as double)
        .where((p) => p.isFinite)
        .toList();

    final double minPrice = prices.reduce((a, b) => a < b ? a : b);
    final double maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final double range = maxPrice - minPrice;

    final double padding = range < 1e-9 ? 1.0 : range * 0.3;
    final double effectiveMinY = (minPrice - padding).clamp(0.0, double.infinity);
    final double effectiveMaxY = maxPrice + padding;

    final double rawInterval = (effectiveMaxY - effectiveMinY) / 4;
    final double yInterval = (rawInterval.isFinite && rawInterval > 1e-9) ? rawInterval : 1.0;

    final double xInterval = (cleanHistory.length / 4).ceilToDouble().clamp(1.0, double.infinity);

    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: RepaintBoundary(
        child: LineChart(
          LineChartData(
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => colorScheme.secondaryContainer,
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((LineBarSpot touchedSpot) {
                    final int idx = touchedSpot.x.toInt();
                    final date = cleanHistory[idx]['data'] as DateTime;
                    return LineTooltipItem(
                      'R\$ ${touchedSpot.y.toStringAsFixed(2)}\n',
                      TextStyle(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: DateFormat('dd/MM/yyyy').format(date),
                          style: TextStyle(
                            color: colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                            fontWeight: FontWeight.normal,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
            ),
            minX: 0,
            maxX: (cleanHistory.length - 1).toDouble(),
            minY: effectiveMinY,
            maxY: effectiveMaxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: xInterval,
                  getTitlesWidget: (value, meta) {
                    final int idx = value.toInt();
                    if (idx < 0 || idx >= cleanHistory.length) return const SizedBox.shrink();
                    final date = cleanHistory[idx]['data'] as DateTime;
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        DateFormat('dd/MM').format(date),
                        style: TextStyle(fontSize: 10, color: colorScheme.outline),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        "R\$${value.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 10, color: colorScheme.outline),
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(cleanHistory.length, (i) {
                  return FlSpot(i.toDouble(), cleanHistory[i]['preco_unitario'] as double);
                }),
                isCurved: true,
                preventCurveOverShooting: true,
                color: colorScheme.primary,
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, idx) {
                    final date = cleanHistory[idx]['data'] as DateTime;
                    final bool isCurrent = date.isAtSameMomentAs(widget.currentPurchaseDate);
                    return FlDotCirclePainter(
                      radius: isCurrent ? 6 : 4,
                      color: isCurrent ? Colors.orange : colorScheme.primary,
                      strokeWidth: 2,
                      strokeColor: colorScheme.surface,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.3),
                      colorScheme.primary.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
