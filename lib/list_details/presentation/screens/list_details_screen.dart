import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_bottom_sheet.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_details_app_bar.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_details_items.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details_bloc.dart';

class ListDetailsScreen extends StatefulWidget {
  const ListDetailsScreen({super.key});

  @override
  State<ListDetailsScreen> createState() => _ListDetailsScreenState();
}

class _ListDetailsScreenState extends State<ListDetailsScreen> {
  static const double topCardHeight = 150;

  late final ScrollController _controller;
  double _topCardParallaxOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScroll);
    _controller.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_controller.hasClients) {
      final offset = _controller.offset;
      setState(() {
        _topCardParallaxOffset = -offset * 0.20;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocBuilder<ListDetailsBloc, ListDetailsState>(
        builder: (context, state) {
          return Stack(
            children: [
              Positioned(
                top: statusBarHeight + _topCardParallaxOffset,
                left: 0,
                right: 0,
                child: ListDetailsAppBar(topCardHeight: topCardHeight),
              ),
              Positioned(
                top: topCardHeight + statusBarHeight + 2,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child:
                      state is ListDetailsLoading
                          ? const LinearProgressIndicator()
                          : const SizedBox(height: 4),
                ),
              ),
              ListDetailsItems(
                controller: _controller,
                topCardHeight: topCardHeight + statusBarHeight,
              ),
              const ListBottomSheet(),
            ],
          );
        },
      ),
    );
  }
}
