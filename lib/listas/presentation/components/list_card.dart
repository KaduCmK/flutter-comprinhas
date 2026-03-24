import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';
import 'package:flutter_comprinhas/listas/presentation/components/edit_list_dialog.dart';
import 'package:flutter_comprinhas/listas/presentation/screens/bloc/listas_bloc.dart';
import 'package:flutter_comprinhas/main.dart';
import 'package:flutter_comprinhas/shared/entities/unit.dart';
import 'package:flutter_comprinhas/shared/widgets/overlapping_avatars.dart';
import 'package:go_router/go_router.dart';

class ListCard extends StatelessWidget {
  final ListaCompra list;
  final List<Unit> units;

  const ListCard({super.key, required this.list, required this.units});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasImage = list.backgroundImage != null;
    final textColor = hasImage ? Colors.white : null;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push('/list/${list.id}');
        },
        onLongPress: () {
          final currentUserId = supabase.auth.currentUser?.id;
          if (currentUserId != list.ownerId) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Apenas o dono da lista pode editá-la.'),
              ),
            );
            return;
          }
          showDialog(
            context: context,
            builder:
                (_) => BlocProvider.value(
                  value: context.read<ListasBloc>(),
                  child: EditListDialog(list: list),
                ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            image: hasImage
                ? DecorationImage(
                    image: NetworkImage(list.backgroundImage!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: hasImage
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black87,
                        Colors.black12,
                        Colors.black54,
                        Colors.black87,
                      ],
                      stops: [0.0, 0.3, 0.7, 1.0],
                    )
                  : null,
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  list.name,
                  style: textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: textColor),
                    const SizedBox(width: 4),
                    Text(
                      list.createdAtFormatted,
                      style: textTheme.bodySmall?.copyWith(color: textColor),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.people, size: 16, color: textColor),
                    const SizedBox(width: 4),
                    Text(
                      "${list.members.length} participantes",
                      style: TextStyle(color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OverlappingAvatars(list: list),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
