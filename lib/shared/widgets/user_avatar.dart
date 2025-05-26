import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/main.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: CircleAvatar(
        foregroundImage: NetworkImage(
          supabase.auth.currentUser!.userMetadata!["avatar_url"],
        ),
      ),
    );
  }
}
