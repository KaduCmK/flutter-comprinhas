import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/purchase_with_nfe_preview.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/close_purchase_with_nfe/close_purchase_with_nfe_cubit.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/close_purchase_with_nfe/close_purchase_with_nfe_state.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ClosePurchaseWithNfeScreen extends StatefulWidget {
  const ClosePurchaseWithNfeScreen({super.key});

  @override
  State<ClosePurchaseWithNfeScreen> createState() =>
      _ClosePurchaseWithNfeScreenState();
}

class _ClosePurchaseWithNfeScreenState
    extends State<ClosePurchaseWithNfeScreen> {
  final _keyController = TextEditingController();

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
    await context.read<ClosePurchaseWithNfeCubit>().loadPreview(accessKey);
  }

  Future<void> _loadPreview() async {
    await context.read<ClosePurchaseWithNfeCubit>().loadPreview(
      _keyController.text,
    );
  }

  Future<void> _confirm() async {
    await context.read<ClosePurchaseWithNfeCubit>().confirmPurchase(
      _keyController.text,
    );
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
      child: BlocConsumer<ClosePurchaseWithNfeCubit, ClosePurchaseWithNfeState>(
        listener: (context, state) {
          if (state.status == ClosePurchaseWithNfeStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Compra com nota fiscal registrada.'),
              ),
            );
            context.read<ClosePurchaseWithNfeCubit>().acknowledgeSuccess();
            context.pop();
          }
        },
        builder: (context, state) {
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
                        onPressed:
                            state.isLoadingPreview || state.isConfirming
                                ? null
                                : _scanQrCode,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Escanear QR Code'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed:
                            state.isLoadingPreview || state.isConfirming
                                ? null
                                : _loadPreview,
                        child: const Text('Revisar nota'),
                      ),
                    ),
                  ],
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        state.errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],
                if (state.isLoadingPreview) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (state.preview != null) ...[
                  const SizedBox(height: 24),
                  _InvoiceSummaryCard(
                    invoice: state.preview!.invoice,
                    summary: state.displayedSummary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Itens da cesta',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...state.preview!.cartItems.map(
                    (item) => _buildCartReviewCard(item, state),
                  ),
                  if (state.displayedExtraItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Itens extras da nota',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...state.displayedExtraItems.map(
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
                    onPressed: state.canConfirm ? _confirm : null,
                    icon:
                        state.isConfirming
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
        },
      ),
    );
  }

  Widget _buildCartReviewCard(
    CartReviewItem item,
    ClosePurchaseWithNfeState state,
  ) {
    final theme = Theme.of(context);
    final selectedManualMatch = state.manualMatches[item.cartItemId];
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
                    value: ClosePurchaseWithNfeUi.ignoreCartItemSelection,
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
                  context.read<ClosePurchaseWithNfeCubit>().setManualMatch(
                    item.cartItemId,
                    value,
                  );
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
