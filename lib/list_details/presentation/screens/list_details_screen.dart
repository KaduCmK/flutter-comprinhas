import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_details_app_bar.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_details_items.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details_bloc.dart';

class ListDetailsScreen extends StatefulWidget {
  const ListDetailsScreen({super.key});

  @override
  State<ListDetailsScreen> createState() => _ListDetailsScreenState();
}

class _ListDetailsScreenState extends State<ListDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: BlocBuilder<ListDetailsBloc, ListDetailsState>(
        // Mantido se ListDetailsAppBar usar o estado
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                ListDetailsAppBar(),
                Expanded(child: ListDetailsItems()),
              ],
            ),
          );
        },
      ),
    );
  }
}
