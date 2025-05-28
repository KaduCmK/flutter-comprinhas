import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details_bloc.dart';

class ListDetailsAppBar extends StatelessWidget {
  final double topCardHeight;
  const ListDetailsAppBar({super.key, required this.topCardHeight});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListDetailsBloc, ListDetailsState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SizedBox(
            height: topCardHeight,
            child: Card(
              elevation: 2,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.list!.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            context.read<ListDetailsBloc>().add(
                              AddItemToListEvent(
                                itemName: "itemName",
                                amount: 1,
                                unitId: "b66405d7-f57a-4183-95e6-6bb9c9ba71dd",
                              ),
                            );
                          },
                          child: const Text("Adicionar"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
