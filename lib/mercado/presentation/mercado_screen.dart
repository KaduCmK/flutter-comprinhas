import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/mercado/presentation/bloc/mercado_bloc.dart';
import 'package:flutter_comprinhas/shared/entities/purchase_history.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MercadoScreen extends StatelessWidget {
  const MercadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MercadoBloc, MercadoState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<MercadoBloc>().add(LoadNfeHistory());
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildSummaryCard(context, state),
                ),
              ),
              if (state.status == MercadoStatus.sending)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      color: Colors.blueAccent,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              "Processando sua nota fiscal...",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (state.status == MercadoStatus.error && state.history.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: ListTile(
                        leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer),
                        title: Text(
                          "Falha no processamento",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          state.errorMessage ?? "",
                          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onErrorContainer),
                          onPressed: () => context.read<MercadoBloc>().add(ClearError()),
                        ),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Histórico de Notas",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (state.status == MercadoStatus.loading && state.history.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.status == MercadoStatus.error && state.history.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.errorMessage ?? "Erro ao carregar"),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<MercadoBloc>().add(LoadNfeHistory()),
                          child: const Text("Tentar novamente"),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _buildHistoryList(state.history),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, MercadoState state) {
    int totalNotes = state.history.length;
    int totalItems = state.history.fold(0, (sum, p) => sum + p.items.length);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, Icons.receipt_long, "Notas", totalNotes.toString()),
                _buildStatItem(context, Icons.shopping_basket, "Itens", totalItems.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 30),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildHistoryList(List<PurchaseHistory> history) {
    if (history.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text("Nenhuma nota fiscal processada ainda.")),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final purchase = history[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.description)),
              title: Text("Nota de ${DateFormat('dd/MM/yyyy HH:mm').format(purchase.confirmedAt)}"),
              subtitle: Text("${purchase.items.length} itens • Por ${purchase.confirmedBy}"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/nfe-details', extra: purchase);
              },
            ),
          );
        },
        childCount: history.length,
      ),
    );
  }
}
