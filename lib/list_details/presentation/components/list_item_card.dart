import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:flutter_comprinhas/list_details/presentation/components/preco_sugerido_chip.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/cart/cart_bloc.dart';
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
      child: ListTile(
        title: RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: '${item.amount}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: item.unit.abbreviation,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              TextSpan(
                text: ' x ',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              TextSpan(
                text: item.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        subtitle: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                item.createdBy.userMetadata?['picture'],
                height: 24,
                width: 24,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.calendar_month),
            Text(DateFormat('dd/MM/yyyy').format(item.createdAt)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.precoSugerido != null)
              PrecoSugeridoChip(precoSugerido: item.precoSugerido),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                inCart ? Icons.remove_shopping_cart : Icons.add_shopping_cart,
                color: inCart ? Colors.redAccent : null,
                size: 30,
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
