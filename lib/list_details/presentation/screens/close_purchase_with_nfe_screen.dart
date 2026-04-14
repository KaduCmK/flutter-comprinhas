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
  static const String _ignoreCartItemSelection = '__ignore_cart_item__';

  final _keyController = TextEditingController();
  final _repository = sl<ListasRepository>();
  PurchaseWithNfePreview? _preview;
  Map<String, String> _manualMatches = {};
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

  Set<String> get _selectedInvoiceItemTempIds {
    if (_preview == null) return const {};

    final selectedIds = <String>{};
    for (final item in _preview!.cartItems) {
      if (item.status == CartReviewStatus.matched &&
          item.selectedInvoiceItemTempId != null) {
        selectedIds.add(item.selectedInvoiceItemTempId!);
      }

      if (item.status == CartReviewStatus.ambiguous) {
        final manualSelection = _manualMatches[item.cartItemId];
        if (manualSelection != null &&
            manualSelection != _ignoreCartItemSelection) {
          selectedIds.add(manualSelection);
        }
      }
    }

    return selectedIds;
  }

  List<InvoiceExtraItem> get _displayedExtraItems {
    final preview = _preview;
    if (preview == null) return const [];

    final selectedIds = _selectedInvoiceItemTempIds;
    return preview.extraItems
        .where((item) => !selectedIds.contains(item.invoiceItemTempId))
        .toList();
  }

  ReviewSummary get _displayedSummary {
    final preview = _preview;
    if (preview == null) {
      return const ReviewSummary(
        matchedItemsCount: 0,
        ambiguousItemsCount: 0,
        unmatchedItemsCount: 0,
        invoiceExtraItemsCount: 0,
      );
    }

    var matchedItemsCount = 0;
    var ambiguousItemsCount = 0;
    var unmatchedItemsCount = 0;

    for (final item in preview.cartItems) {
      switch (item.status) {
        case CartReviewStatus.matched:
          matchedItemsCount += 1;
          break;
        case CartReviewStatus.ambiguous:
          final manualSelection = _manualMatches[item.cartItemId];
          if (manualSelection == _ignoreCartItemSelection) {
            unmatchedItemsCount += 1;
          } else if (manualSelection != null) {
            matchedItemsCount += 1;
          } else {
            ambiguousItemsCount += 1;
          }
          break;
        case CartReviewStatus.unmatched:
          unmatchedItemsCount += 1;
          break;
      }
    }

    return ReviewSummary(
      matchedItemsCount: matchedItemsCount,
      ambiguousItemsCount: ambiguousItemsCount,
      unmatchedItemsCount: unmatchedItemsCount,
      invoiceExtraItemsCount: _displayedExtraItems.length,
    );
  }

  String _manualMatchLabel({
    required String productName,
    required double unitPrice,
  }) {
    return '$productName • R\$ ${unitPrice.toStringAsFixed(2)}';
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
        _manualMatches = {};
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
        {
          for (final entry in _manualMatches.entries)
            entry.key:
                entry.value == _ignoreCartItemSelection ? null : entry.value,
        },
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

  Future<bool> _confirmExit() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sair da confirmação?'),
            content: const Text(
              'Se você sair agora, o cadastro da nota e o fechamento da compra não serão concluídos.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Continuar aqui'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sair'),
              ),
            ],
          ),
    );

    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldLeave = await _confirmExit();
        if (shouldLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
                summary: _displayedSummary,
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
              if (_displayedExtraItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Itens extras da nota',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ..._displayedExtraItems.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item.productName),
                      subtitle: Text(
                        '${item.quantity.toStringAsFixed(2)} ${item.unitLabel ?? 'UN'}',
                      ),
                      trailing: Text(
                        'R\$ ${item.totalPrice.toStringAsFixed(2)}',
                      ),
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
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Escolha o item correspondente',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: _ignoreCartItemSelection,
                    child: Text(
                      'Desconsiderar item da cesta',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...item.candidates.map(
                    (candidate) => DropdownMenuItem<String?>(
                      value: candidate.invoiceItemTempId,
                      child: Text(
                        _manualMatchLabel(
                          productName: candidate.productName,
                          unitPrice: candidate.unitPrice,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
                selectedItemBuilder:
                    (context) => [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Desconsiderar item da cesta',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      ...item.candidates.map(
                        (candidate) => Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _manualMatchLabel(
                              productName: candidate.productName,
                              unitPrice: candidate.unitPrice,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                onChanged: (value) {
                  setState(() {
                    if (value == null) {
                      _manualMatches.remove(item.cartItemId);
                    } else {
                      _manualMatches[item.cartItemId] = value;
                    }
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
