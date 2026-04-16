import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/main.dart';

class UserAvatar extends StatelessWidget {
  final int size;
  const UserAvatar({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final metadata = supabase.auth.currentUser?.userMetadata;
    final avatarUrl =
        metadata?['avatar_url'] as String? ?? metadata?['picture'] as String?;

    return Padding(
      padding: const EdgeInsets.all(6),
      child: CircleAvatar(
        radius: size / 2,
        foregroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        onForegroundImageError: (_, _) {},
        child: avatarUrl == null ? const Icon(Icons.person_outline) : null,
      ),
    );
  }
}
