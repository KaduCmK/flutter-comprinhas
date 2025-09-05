import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/mercado/presentation/bloc/mercado_bloc.dart';
import 'package:flutter_comprinhas/mercado/presentation/components/scanner_overlay.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EnviarNotaScreen extends StatefulWidget {
  const EnviarNotaScreen({super.key});

  @override
  State<EnviarNotaScreen> createState() => _EnviarNotaScreenState();
}

class _EnviarNotaScreenState extends State<EnviarNotaScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAndSend(String code) {
    if (isProcessing) return;

    final uri = Uri.tryParse(code);
    if (uri == null || !uri.host.contains('fazenda.rj.gov.br')) {
      _showErrorSnackBar('QR Code inválido.');
      return;
    }

    // Lógica de extração corrigida
    final accessKey = uri.queryParameters['p']?.split('|').first;

    if (accessKey == null ||
        accessKey.length != 44 ||
        BigInt.tryParse(accessKey) == null) {
      _showErrorSnackBar('Chave de acesso inválida no QR Code.');
      return;
    }

    setState(() {
      isProcessing = true;
    });

    // Sai da tela
    context.pop();

    // Mostra a snackbar de sucesso na tela anterior
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR Code lido com sucesso! Enviando nota...'),
        backgroundColor: Colors.blue,
      ),
    );

    // Envia a chave JÁ VALIDADA para o BLoC
    context.read<MercadoBloc>().add(SendNfe(accessKey));
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: 250,
      height: 250,
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            scanWindow: scanWindow,
            onDetect: (barcodes) {
              final String? code = barcodes.barcodes.first.rawValue;
              if (code != null) {
                _validateAndSend(code);
              }
            },
          ),
          CustomPaint(painter: ScannerOverlay(scanWindow)),
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(128),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Aponte para o QR Code da NFe',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                onPressed: () => _controller.toggleTorch(),
                icon: Icon(Icons.flash_off, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withAlpha(128),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
