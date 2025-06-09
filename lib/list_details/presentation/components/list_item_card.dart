import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/list_details/domain/entities/list_item.dart';
import 'package:intl/intl.dart';

class ListItemCard extends StatelessWidget {
  final ListItem item;
  final Animation<double> animation;
  final Function(ListItem item) onDismiss;

  const ListItemCard({
    super.key,
    required this.item,
    required this.animation,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: FadeTransition(
        opacity: animation,
        child: Dismissible(
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
            onDismiss(item);
          },
          child: ListTile(
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
              onPressed: () {},
              icon: Icon(Icons.add_shopping_cart, size: 30),
            ),
          ),
        ),
      ),
    );
  }
}
