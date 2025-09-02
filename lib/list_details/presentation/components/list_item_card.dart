import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:flutter_comprinhas/list_details/presentation/screens/bloc/list_details_bloc.dart';
import 'package:intl/intl.dart';

class ListItemCard extends StatelessWidget {
  final ListItem item;
  final Animation<double>? animation;
  final Function(ListItem item)? onDismiss;
  
  final bool inCart;
  final String? cartItemId;

  const ListItemCard({
    super.key,
    required this.item,
    this.animation,
    this.onDismiss,
    this.inCart = false,
    this.cartItemId,
  });

  @override
  Widget build(BuildContext context) {
    // O conteúdo do Card que será reutilizado
    final cardContent = ListTile(
      title: RichText(
        text: TextSpan(
          children: <TextSpan>[
                  TextSpan(
                    text: '${item.amount}',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
        ),
      ),
      subtitle: Row(
              spacing: 2,
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
                Icon(Icons.calendar_month),
                Text(DateFormat('dd/MM/yyyy').format(item.createdAt)),
              ],
            ),
      trailing: IconButton(
        // O ícone muda baseado no estado 'inCart'
        icon: Icon(
          inCart ? Icons.remove_shopping_cart : Icons.add_shopping_cart,
          color: inCart ? Colors.redAccent : null, // Cor diferente no carrinho
          size: 30,
        ),
        onPressed: () {
          final bloc = context.read<ListDetailsBloc>();
          if (inCart) {
            // Se está no carrinho, deve ter um cartItemId para poder ser removido
            assert(cartItemId != null, 'cartItemId não pode ser nulo se inCart for true');
            bloc.add(RemoveFromCartEvent(cartItemId!));
          } else {
            // Se não está no carrinho, adiciona
            bloc.add(AddToCartEvent(item.id));
          }
        },
      ),
    );

    // O widget que será construído
    Widget card = cardContent;

    // Se a função onDismiss for fornecida, envolvemos com Dismissible
    if (onDismiss != null) {
      card = Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.startToEnd,
        background: Container(
          color: Theme.of(context).colorScheme.error,
          padding: const EdgeInsets.only(left: 16),
          alignment: Alignment.centerLeft,
          child: Icon(
            Icons.delete,
            color: Theme.of(context).colorScheme.onError,
          ),
        ),
        onDismissed: (direction) {
          onDismiss!(item);
        },
        child: card,
      );
    }

    // Se a animação for fornecida, envolvemos com os widgets de transição
    if (animation != null) {
      card = SizeTransition(
        sizeFactor: CurvedAnimation(parent: animation!, curve: Curves.easeOut),
        child: FadeTransition(
          opacity: animation!,
          child: card,
        ),
      );
    }

    return card;
  }
}