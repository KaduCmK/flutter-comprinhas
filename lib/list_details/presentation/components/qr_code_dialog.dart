import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeDialog extends StatelessWidget {
  final String listId;

  const QrCodeDialog({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    final deepLink = 'comprinhas://join/$listId';

    return AlertDialog(
      title: const Text("Compartilhar Lista"),
      content: SizedBox(
        width: 300,
        height: 300,
        child: QrImageView(data: deepLink, version: QrVersions.auto, backgroundColor: Colors.white,),
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
