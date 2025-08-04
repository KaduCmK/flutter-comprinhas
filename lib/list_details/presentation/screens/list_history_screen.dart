import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details_bloc.dart';
import 'package:intl/intl.dart';

class ListHistoryScreen extends StatefulWidget {
  final String listId;
  const ListHistoryScreen({super.key, required this.listId});

  @override
  State<ListHistoryScreen> createState() => _ListHistoryScreenState();
}

class _ListHistoryScreenState extends State<ListHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Dispara o evento pra carregar o histórico assim que a tela abre
    context.read<ListDetailsBloc>().add(LoadPurchaseHistoryEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Histórico de Compras")),
      body: BlocBuilder<ListDetailsBloc, ListDetailsState>(
        builder: (context, state) {
          if (state is ListDetailsLoading && state.purchaseHistory.isEmpty) {
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
                      Text(
                        'Compra de ${historyEntry.confirmedBy} em ${DateFormat('dd/MM/yyyy HH:mm').format(historyEntry.confirmedAt.toLocal())}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(),
                      ...historyEntry.items.map(
                        (item) => ListTile(
                          title: Text(item.name),
                          trailing: Text('${item.amount} ${item.unit?.abbreviation ?? ''}'),
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
