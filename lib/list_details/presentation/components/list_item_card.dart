import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/preco_sugerido_chip.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/cart/cart_bloc.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details/list_details_bloc.dart';
import 'package:flutter_comprinhas/shared/utils/unit_converter.dart';
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';
import 'package:intl/intl.dart';

class ListItemCard extends StatelessWidget {
  final ListItem item;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  final bool inCart;
  final String? cartItemId;

  const ListItemCard({
    super.key,
    required this.item,
    this.onDelete,
    this.onEdit,
    this.inCart = false,
    this.cartItemId,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final listDetailsState = context.watch<ListDetailsBloc>().state;

    final bool priceForecastEnabled =
        listDetailsState.list?.priceForecastEnabled ?? false;
    final bool hasAnySuggestedPrice =
        listDetailsState.items.any((i) => i.precoSugerido != null);

    final bool isSuggestingPrice =
        listDetailsState.suggestingPriceItemId == item.id;

    final bool showSuggestButton =
        !priceForecastEnabled &&
        hasAnySuggestedPrice &&
        item.precoSugerido == null;

    // Calcular o subtotal apenas se houver preco sugerido
    double? subtotal;
    if (item.precoSugerido != null) {
      double multiplier = 1.0;
      if (item.unidadePrecoSugerido != null) {
        multiplier = UnitConverter.getConversionFactor(
          item.unit.abbreviation,
          item.unidadePrecoSugerido!,
        );
      }
      subtotal = item.precoSugerido! * multiplier * item.amount;
    }

    return SwipeActionCell(
      key: ObjectKey(item.id),
      backgroundColor: Colors.transparent,
      leadingActions: [
        if (onDelete != null)
          SwipeAction(
            icon: Icon(Icons.delete, color: colorScheme.error),
            color: colorScheme.secondaryContainer,
            onTap: (_) => onDelete!.call(),
          ),
        if (onEdit != null)
          SwipeAction(
            icon: Icon(Icons.edit, color: colorScheme.primary),
            color: colorScheme.secondaryContainer,
            onTap: (_) => onEdit!.call(),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: '${item.amount}',
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: item.unit.abbreviation,
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall!.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextSpan(
                          text: ' x ',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall!.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextSpan(
                          text: item.name,
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          item.createdBy.userMetadata?['picture'],
                          height: 20,
                          width: 20,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.calendar_month, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(item.createdAt),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (item.precoSugerido != null)
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (subtotal != null)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: AnimatedFlipCounter(
                            value: subtotal,
                            prefix: "R\$ ",
                            fractionDigits: 2,
                            decimalSeparator: ',',
                            thousandSeparator: '.',
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            textStyle: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      Flexible(child: PrecoSugeridoChip(item: item)),
                    ],
                  ),
                ),
              ),
            if (isSuggestingPrice)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (showSuggestButton)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: TextButton.icon(
                  onPressed: () {
                    context.read<ListDetailsBloc>().add(SugerirPreco(item));
                  },
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text(
                    'Sugerir Preço',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            IconButton(
              icon: Icon(
                inCart ? Icons.remove_shopping_cart : Icons.add_shopping_cart,
                color: inCart ? Colors.redAccent : null,
                size: 28,
              ),
              onPressed: () {
                final bloc = context.read<CartBloc>();
                if (inCart) {
                  assert(
                    cartItemId != null,
                    'cartItemId não pode ser nulo se inCart for true',
                  );
                  bloc.add(RemoveFromCart(cartItemId!));
                } else {
                  bloc.add(AddToCart(item.id));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
