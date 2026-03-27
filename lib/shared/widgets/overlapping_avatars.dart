import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/listas/domain/entities/lista_compra.dart';

class OverlappingAvatars extends StatelessWidget {
  final ListaCompra list;
  final double size;
  final double overlap;

  const OverlappingAvatars({
    super.key,
    required this.list,
    this.size = 28,
    this.overlap = 12,
  });

  @override
  Widget build(BuildContext context) {
    final ownerMember =
        list.members.where((m) => m.user.id == list.ownerId).firstOrNull;
    final otherMembers =
        list.members.where((m) => m.user.id != list.ownerId).toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ownerMember != null) ...[
          _buildAvatarWithCrown(
            context,
            ownerMember.user.userMetadata?["avatar_url"] ??
                ownerMember.user.userMetadata?["picture"],
          ),
          if (otherMembers.isNotEmpty) SizedBox(width: size / 2),
        ],
        if (otherMembers.isNotEmpty)
          SizedBox(
            height: size,
            width: size + (otherMembers.length - 1) * (size - overlap),
            child: Stack(
              children:
                  List.generate(otherMembers.length, (index) {
                    final member = otherMembers[index];
                    final url =
                        member.user.userMetadata?["avatar_url"] ??
                        member.user.userMetadata?["picture"];
                    return Positioned(
                      left: index * (size - overlap),
                      child: CircleAvatar(
                        radius: size / 2,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child: CircleAvatar(
                          radius: size / 2 - 1.5,
                          backgroundImage:
                              url != null ? NetworkImage(url) : null,
                          child:
                              url == null
                                  ? const Icon(Icons.person, size: 16)
                                  : null,
                        ),
                      ),
                    );
                  }).reversed.toList(), // Reversed to have first items on top
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarWithCrown(BuildContext context, String? url) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundImage: url != null ? NetworkImage(url) : null,
          child: url == null ? const Icon(Icons.person, size: 16) : null,
        ),
        Positioned(
          top: -8,
          right: -6,
          child: Icon(
            Icons.workspace_premium,
            color: Colors.amber,
            size: size * 0.7,
          ),
        ),
      ],
    );
  }
}
