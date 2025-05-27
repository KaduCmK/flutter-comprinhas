import 'package:flutter/material.dart';

class ListBottomSheet extends StatefulWidget {
  const ListBottomSheet({super.key});

  @override
  State<ListBottomSheet> createState() => _ListBottomSheetState();
}

class _ListBottomSheetState extends State<ListBottomSheet> {
  final _sheet = GlobalKey();
  late final DraggableScrollableController _controller;

  final sheetMinSize = 0.16;
  final sheetMaxSize = 0.4;

  DraggableScrollableSheet get sheet =>
      (_sheet.currentWidget as DraggableScrollableSheet);

  @override
  void initState() {
    super.initState();
    _controller = DraggableScrollableController()..addListener(_onDrag);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDrag() {
    final currentSize = _controller.size;
    if (currentSize <= 0.01) _animateSheet(sheet.snapSizes!.first);
  }

  void _animateSheet(double size) {
    _controller.animateTo(
      size,
      duration: const Duration(milliseconds: 75),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      key: _sheet,
      initialChildSize: sheetMinSize,
      maxChildSize: sheetMaxSize,
      minChildSize: 0,
      snap: true,
      snapSizes: [sheetMinSize, sheetMaxSize],
      controller: _controller,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                blurRadius: 16,
                spreadRadius: 4,
                offset: Offset(0, -4),
                color: Colors.black12,
              ),
            ],
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Container(
                      height: 8,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceDim,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
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
