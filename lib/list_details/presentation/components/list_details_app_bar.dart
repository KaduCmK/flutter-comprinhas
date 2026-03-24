import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/gemini_animated_border.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/list_details_appbar_actions.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/new_item_dialog.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details/list_details_bloc.dart';
import 'package:flutter_comprinhas/shared/widgets/overlapping_avatars.dart';
import 'package:go_router/go_router.dart';

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
                      InkWell(
                        onTap: () {
                          if (state.list != null) {
                            context.push('/list/${state.list!.id}/info', extra: state.list);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  state.list?.name ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.headlineMedium?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Total: ",
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
                          if (state.list != null && state.list!.members.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            Container(
                              height: 16,
                              width: 1,
                              color: colorScheme.outlineVariant,
                            ),
                            const SizedBox(width: 16),
                            OverlappingAvatars(list: state.list!, size: 24, overlap: 10),
                          ],
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
                          isParsing: state.isParsingNlp,
                          gradientColors: [
                            colorScheme.primary,
                            colorScheme.secondary,
                            colorScheme.tertiary,
                          ],
                          child: TextFormField(
                            controller: _nlpController,
                            focusNode: _nlpFocusNode,
                            enabled: !state.isParsingNlp,
                            decoration: InputDecoration(
                              hintText: "Adicionar item",
                              prefixIcon: ShaderMask(
                                shaderCallback:
                                    (bounds) => LinearGradient(
                                      colors: [
                                        colorScheme.primary,
                                        colorScheme.secondary,
                                        colorScheme.tertiary,
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
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: state.isParsingNlp
                                    ? null
                                    : () => _submitNlp(context),
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
