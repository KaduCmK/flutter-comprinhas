import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/core/config/service_locator.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/purchase_with_nfe_preview.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/cart/cart_bloc.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/listas/domain/listas_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClosePurchaseWithNfeScreen extends StatefulWidget {
  const ClosePurchaseWithNfeScreen({super.key});

  @override
  State<ClosePurchaseWithNfeScreen> createState() =>
      _ClosePurchaseWithNfeScreenState();
}

class _ClosePurchaseWithNfeScreenState
    extends State<ClosePurchaseWithNfeScreen> {
  final _keyController = TextEditingController();
  final _repository = sl<ListasRepository>();
  PurchaseWithNfePreview? _preview;
  Map<String, String?> _manualMatches = {};
  bool _isLoading = false;
  bool _isConfirming = false;
  String? _error;

  List<String> get _cartItemIds {
    final cartBloc = context.read<CartBloc>();
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (cartBloc.state.cartMode == CartMode.individual &&
        currentUserId != null) {
      return cartBloc.state.cartItems
          .where((item) => item.user.id == currentUserId)
          .map((item) => item.id)
          .toList();
    }
    return cartBloc.state.cartItems.map((item) => item.id).toList();
  }

  bool get _canConfirm {
    if (_preview == null || _isConfirming) return false;
    for (final item in _preview!.cartItems.where((item) => item.needsReview)) {
      if (!_manualMatches.containsKey(item.cartItemId)) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _scanQrCode() async {
    final accessKey = await context.push<String>('/enviar-nfe');
    if (!mounted || accessKey == null) return;
    _keyController.text = accessKey;
    await _loadPreview();
  }

  Future<void> _loadPreview() async {
    final chaveAcesso = _keyController.text.trim();
    if (chaveAcesso.length != 44) {
      setState(
        () => _error = 'Informe uma chave de acesso válida com 44 dígitos.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _preview = null;
      _manualMatches = {};
    });

    try {
      final preview = await _repository.previewPurchaseWithNfe(
        _cartItemIds,
        chaveAcesso,
      );
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _manualMatches = {
          for (final item in preview.cartItems.where(
            (item) => item.needsReview,
          ))
            item.cartItemId: null,
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirm() async {
    if (!_canConfirm) return;

    setState(() {
      _isConfirming = true;
      _error = null;
    });

    try {
      await _repository.confirmPurchaseWithNfe(
        _cartItemIds,
        _keyController.text.trim(),
        _manualMatches,
      );
      if (!mounted) return;
      context.read<CartBloc>().add(LoadCart());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compra com nota fiscal registrada.')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Fechar compra com nota')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Escaneie ou cole a chave da NF para revisar os matches antes de concluir a compra.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _keyController,
            decoration: const InputDecoration(
              labelText: 'Chave de acesso',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            maxLength: 44,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading || _isConfirming ? null : _scanQrCode,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Escanear QR Code'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isLoading || _isConfirming ? null : _loadPreview,
                  child: const Text('Revisar nota'),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
          ],
          if (_isLoading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_preview != null) ...[
            const SizedBox(height: 24),
            _InvoiceSummaryCard(
              invoice: _preview!.invoice,
              summary: _preview!.summary,
            ),
            const SizedBox(height: 16),
            Text(
              'Itens da cesta',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._preview!.cartItems.map(_buildCartReviewCard),
            if (_preview!.extraItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Itens extras da nota',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._preview!.extraItems.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(item.productName),
                    subtitle: Text(
                      '${item.quantity.toStringAsFixed(2)} ${item.unitLabel ?? 'UN'}',
                    ),
                    trailing: Text('R\$ ${item.totalPrice.toStringAsFixed(2)}'),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _canConfirm ? _confirm : null,
              icon:
                  _isConfirming
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.receipt_long),
              label: const Text('Confirmar compra com nota'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCartReviewCard(CartReviewItem item) {
    final theme = Theme.of(context);
    final selectedManualMatch = _manualMatches[item.cartItemId];
    InvoiceMatchCandidate? selectedCandidate;
    for (final candidate in item.candidates) {
      if (candidate.invoiceItemTempId == selectedManualMatch) {
        selectedCandidate = candidate;
        break;
      }
    }

    Color? accentColor;
    String statusLabel;
    switch (item.status) {
      case CartReviewStatus.matched:
        accentColor = Colors.green;
        statusLabel = 'Match automático';
        break;
      case CartReviewStatus.ambiguous:
        accentColor = Colors.orange;
        statusLabel = 'Revisão obrigatória';
        break;
      case CartReviewStatus.unmatched:
        accentColor = theme.colorScheme.outline;
        statusLabel = 'Não encontrado na nota';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(statusLabel),
                  side: BorderSide(color: accentColor),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${item.amount} ${item.unitLabel ?? ''}'),
            if (item.status == CartReviewStatus.matched &&
                item.selectedProductName != null) ...[
              const SizedBox(height: 8),
              Text(
                'NF: ${item.selectedProductName} • R\$ ${item.recordedUnitPrice?.toStringAsFixed(2) ?? '-'}',
              ),
            ],
            if (item.status == CartReviewStatus.ambiguous) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: selectedManualMatch,
                decoration: const InputDecoration(
                  labelText: 'Escolha o item correspondente',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Desconsiderar item da cesta'),
                  ),
                  ...item.candidates.map(
                    (candidate) => DropdownMenuItem<String?>(
                      value: candidate.invoiceItemTempId,
                      child: Text(
                        '${candidate.productName} • R\$ ${candidate.unitPrice.toStringAsFixed(2)}',
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _manualMatches[item.cartItemId] = value;
                  });
                },
              ),
              if (selectedCandidate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Selecionado: ${selectedCandidate.productName} (${(selectedCandidate.similarity * 100).toStringAsFixed(1)}%)',
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _InvoiceSummaryCard extends StatelessWidget {
  final InvoicePreview invoice;
  final ReviewSummary summary;

  const _InvoiceSummaryCard({required this.invoice, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invoice.mercado.nome,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              invoice.dataEmissao != null
                  ? formatter.format(invoice.dataEmissao!.toLocal())
                  : 'Data de emissão indisponível',
            ),
            const SizedBox(height: 8),
            Text('Total da NF: R\$ ${invoice.valorTotal.toStringAsFixed(2)}'),
            Text('Itens na NF: ${invoice.quantidadeItens}'),
            const Divider(height: 24),
            Text('Matches automáticos: ${summary.matchedItemsCount}'),
            Text('Revisões obrigatórias: ${summary.ambiguousItemsCount}'),
            Text('Itens ignorados da cesta: ${summary.unmatchedItemsCount}'),
            Text('Itens extras da NF: ${summary.invoiceExtraItemsCount}'),
          ],
        ),
      ),
    );
  }
}
