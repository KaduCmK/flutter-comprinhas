import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/listas/presentation/components/list_share_link.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeDialog extends StatelessWidget {
  final String listId;

  const QrCodeDialog({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    final shareLink = ListShareLink.build(listId);

    return AlertDialog(
      title: const Text("Compartilhar Lista"),
      content: SizedBox(
        width: 300,
        height: 300,
        child: QrImageView(
          data: shareLink,
          version: QrVersions.auto,
          backgroundColor: Colors.white,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Fechar"),
        ),
      ],
    );
  }
}
