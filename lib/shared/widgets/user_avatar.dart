import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/main.dart';

class UserAvatar extends StatelessWidget {
  final int size;
  const UserAvatar({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: CircleAvatar(
        radius: size / 2,
        foregroundImage: NetworkImage(
          supabase.auth.currentUser!.userMetadata!["avatar_url"],
        ),
      ),
    );
  }
}
