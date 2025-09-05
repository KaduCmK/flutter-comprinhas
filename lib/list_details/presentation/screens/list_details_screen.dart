import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_details_app_bar.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_item_card.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details/list_details_bloc.dart';

class ListDetailsScreen extends StatefulWidget {
  const ListDetailsScreen({super.key});

  @override
  State<ListDetailsScreen> createState() => _ListDetailsScreenState();
}

class _ListDetailsScreenState extends State<ListDetailsScreen> {
  final _listKey = GlobalKey<SliverAnimatedListState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocBuilder<ListDetailsBloc, ListDetailsState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                snap: true,
                floating: true,
                automaticallyImplyLeading: true,
                expandedHeight: 160,
                flexibleSpace: FlexibleSpaceBar(
                  background: ListDetailsAppBar(),
                ),
              ),

              SliverList.builder(
                key: _listKey,
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return ListItemCard(
                    item: item,
                    onDismiss: (item) {},
                    inCart: false,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}