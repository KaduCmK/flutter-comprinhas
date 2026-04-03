import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/core/config/service_locator.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/history/history_bloc.dart';
import 'package:flutter_comprinhas/mercado/data/mercado_repository.dart';
import 'package:flutter_comprinhas/shared/entities/purchase_history_item.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ListHistoryScreen extends StatefulWidget {
  final String listId;
  const ListHistoryScreen({super.key, required this.listId});

  @override
  State<ListHistoryScreen> createState() => _ListHistoryScreenState();
}

class _ListHistoryScreenState extends State<ListHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Histórico de Compras")),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state.isLoading && state.purchaseHistory.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.purchaseHistory.isEmpty) {
            return const Center(
              child: Text("Nenhuma compra foi registrada ainda."),
            );
          }

          return ListView.builder(
            itemCount: state.purchaseHistory.length,
            itemBuilder: (context, index) {
              final historyEntry = state.purchaseHistory[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Compra de ${historyEntry.confirmedBy} em ${DateFormat('dd/MM/yyyy HH:mm').format(historyEntry.confirmedAt.toLocal())}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (historyEntry.notaFiscalId != null)
                            IconButton(
                              tooltip: 'Ver nota fiscal',
                              onPressed: () async {
                                try {
                                  final purchase = await sl<MercadoRepository>()
                                      .getNfeById(historyEntry.notaFiscalId!);
                                  if (!context.mounted) return;
                                  context.push('/nfe-details', extra: purchase);
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Erro ao carregar nota fiscal: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.receipt_long),
                            ),
                        ],
                      ),
                      const Divider(),
                      ...historyEntry.items.map(
                        (item) => ListTile(
                          title: Text(item.name),
                          subtitle:
                              item.origin ==
                                      PurchaseHistoryItemOrigin.invoiceExtra
                                  ? const Text('Item extra vindo da nota')
                                  : item.recordedUnitPrice != null
                                  ? Text(
                                    'Preço registrado: R\$ ${item.recordedUnitPrice!.toStringAsFixed(2)}',
                                  )
                                  : null,
                          trailing: Text('${item.amount} ${item.unitLabel}'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
