import 'package:flutter/material.dart';

class ListBottomSheet extends StatefulWidget {
  const ListBottomSheet({super.key});

  @override
  State<ListBottomSheet> createState() => _ListBottomSheetState();
}

class _ListBottomSheetState extends State<ListBottomSheet> {
  final _controller = DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.16,
      maxChildSize: 1,
      minChildSize: 0.16,
      expand: true,
      snap: true,
      controller: _controller,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(blurRadius: 4, spreadRadius: 8, offset: Offset(0, -4), color: Colors.black12)
            ],
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Row(
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart, size: 40),
                    Text(
                      "Carrinho",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Expanded(
                      child: Text(
                        "0",
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
