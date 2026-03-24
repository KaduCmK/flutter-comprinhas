import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/gemini_animated_border.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_details_appbar_actions.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/new_item_dialog.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details/list_details_bloc.dart';

class ListDetailsAppBar extends StatefulWidget {
  const ListDetailsAppBar({super.key});

  @override
  State<ListDetailsAppBar> createState() => _ListDetailsAppBarState();
}

class _ListDetailsAppBarState extends State<ListDetailsAppBar> {
  final _nlpController = TextEditingController();
  final _nlpFocusNode = FocusNode();

  @override
  void dispose() {
    _nlpController.dispose();
    _nlpFocusNode.dispose();
    super.dispose();
  }

  void _submitNlp(BuildContext context) {
    final query = _nlpController.text.trim();
    if (query.isNotEmpty) {
      context.read<ListDetailsBloc>().add(AddNaturalLanguageItemToList(query));
      _nlpController.clear();
      _nlpFocusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<ListDetailsBloc, ListDetailsState>(
      listenWhen:
          (previous, current) => previous.isParsingNlp != current.isParsingNlp,
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: Card(
            elevation: 2,
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.list?.name ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Total estimado: ",
                            style: textTheme.titleMedium,
                          ),
                          AnimatedFlipCounter(
                            value: state.estimatedTotal,
                            prefix: "R\$ ",
                            fractionDigits: 2,
                            decimalSeparator: ',',
                            thousandSeparator: '.',
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            textStyle: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  ListDetailsAppbarActions(state: state),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton.filled(
                        onPressed:
                            state.isParsingNlp
                                ? null
                                : () => showDialog(
                                  context: context,
                                  builder: (_) {
                                    return BlocProvider.value(
                                      value: context.read<ListDetailsBloc>(),
                                      child: const NewItemDialog(),
                                    );
                                  },
                                ),
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 32,
                        width: 1,
                        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GeminiAnimatedBorder(
                          child: TextFormField(
                            controller: _nlpController,
                            focusNode: _nlpFocusNode,
                            enabled: !state.isParsingNlp,
                            decoration: InputDecoration(
                              hintText: "Adicionar item",
                              prefixIcon: ShaderMask(
                                shaderCallback:
                                    (bounds) => LinearGradient(
                                      colors: const [
                                        Color(0xFF4285F4),
                                        Color(0xFF9B72CB),
                                        Color(0xFFD96570),
                                      ],
                                    ).createShader(bounds),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                ),
                              ),
                              filled: true,
                              fillColor: colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon:
                                  state.isParsingNlp
                                      ? Container(
                                        padding: const EdgeInsets.all(12),
                                        width: 24,
                                        height: 24,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : IconButton(
                                        icon: const Icon(Icons.send),
                                        onPressed: () => _submitNlp(context),
                                        color: colorScheme.primary,
                                      ),
                            ),
                            textInputAction: TextInputAction.send,
                            onFieldSubmitted: (_) => _submitNlp(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  state.isLoading
                      ? const LinearProgressIndicator()
                      : const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
