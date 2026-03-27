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
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: sl<MercadoRepository>().getProductPriceHistory(item.produtoId!),
            builder: (context, snapshot) {
              final colorScheme = Theme.of(context).colorScheme;
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text("Erro: ${snapshot.error}"),
                );
              }

              final history = snapshot.data ?? [];

              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                itemCount: history.isEmpty ? 5 : history.length + 5,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Text(
                      item.name.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    );
                  }
                  if (index == 1) return const Divider();
                  if (index == 2) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text("Evolução de Preços", style: TextStyle(fontWeight: FontWeight.bold)),
                    );
                  }
                  
                  if (history.isEmpty) {
                    if (index == 3) return const Text("Sem dados históricos.");
                    if (index == 4) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Fechar"),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }

                  // Gráfico de evolução
                  if (index == 3) {
                    final double firstTimestamp = (history.first['data'] as DateTime).millisecondsSinceEpoch.toDouble();
                    final double lastTimestamp = (history.last['data'] as DateTime).millisecondsSinceEpoch.toDouble();
                    
                    // Se só tiver um ponto, não faz sentido mostrar gráfico de linha curva
                    if (firstTimestamp == lastTimestamp) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: Text("Histórico insuficiente para gerar gráfico.")),
                      );
                    }

                    return Container(
                      height: 200,
                      padding: const EdgeInsets.only(right: 24, top: 16, bottom: 16),
                      child: LineChart(
                        LineChartData(
                          minX: firstTimestamp,
                          maxX: lastTimestamp,
                          gridData: const FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                // Intervalo de segurança para não travar a UI
                                interval: (lastTimestamp - firstTimestamp) / 2,
                                getTitlesWidget: (value, meta) {
                                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      DateFormat('dd/MM').format(date),
                                      style: const TextStyle(fontSize: 9),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 45,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    "R\$${value.toStringAsFixed(2)}",
                                    style: const TextStyle(fontSize: 9),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(color: colorScheme.outlineVariant),
                              left: BorderSide(color: colorScheme.outlineVariant),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: history.map((h) {
                                final date = h['data'] as DateTime;
                                return FlSpot(
                                  date.millisecondsSinceEpoch.toDouble(),
                                  h['preco_unitario'] as double,
                                );
                              }).toList(),
                              isCurved: history.length > 2,
                              color: colorScheme.primary,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                                  final bool isCurrent = date.isAtSameMomentAs(widget.purchase.dataEmissao ?? widget.purchase.confirmedAt);
                                  return FlDotCirclePainter(
                                    radius: isCurrent ? 6 : 3,
                                    color: isCurrent ? Colors.orange : colorScheme.primary,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: colorScheme.primary.withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (index < history.length + 4) {
                    final hist = history[index - 4];
                    final double price = hist['preco_unitario'];
                    final DateTime date = hist['data'];
                    final bool isCurrent = date.isAtSameMomentAs(widget.purchase.dataEmissao ?? widget.purchase.confirmedAt);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.history, 
                        color: isCurrent ? colorScheme.primary : null
                      ),
                      title: Text(
                        "R\$ ${price.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : null,
                          color: isCurrent ? colorScheme.primary : null
                        ),
                      ),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
                      trailing: isCurrent ? const Chip(label: Text("Nesta nota", style: TextStyle(fontSize: 10))) : null,
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Fechar"),
                    ),
                  );
                },
              );
            }
          ),
        ),
      ),
    );
  }
}
