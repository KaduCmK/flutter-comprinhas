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
              if (isProcessing) return;

              final String? code = barcodes.barcodes.first.rawValue;
              if (code == null) return;

              setState(() {
                isProcessing = true;
              });
              context.pop();
              context.read<MercadoBloc>().add(SendNfe(code));
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
                  color: Colors.black.withValues(alpha: 0.5),
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
                icon: Icon(
                  _controller.torchEnabled ? Icons.flash_off : Icons.flash_on,
                  color: Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
