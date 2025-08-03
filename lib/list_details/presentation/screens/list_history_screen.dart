import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details_bloc.dart';

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
    context.read<ListDetailsBloc>().add(LoadPurchaseHistoryEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Histórico")));
  }
}
