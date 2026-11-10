import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Abre la camara y devuelve (con pop) el texto del primer QR leido.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller =
      MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _leido = false;

  void _alDetectar(BarcodeCapture captura) {
    if (_leido) return; // evita procesar el mismo QR varias veces
    for (final b in captura.barcodes) {
      final valor = b.rawValue;
      if (valor != null && valor.isNotEmpty) {
        _leido = true;
        Navigator.pop(context, valor);
        return;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escaneando QR...'),
        actions: [
          IconButton(icon: const Icon(Icons.flashlight_on), tooltip: 'Linterna', onPressed: () => _controller.toggleTorch()),
        ],
      ),
      body: Stack(children: [
        MobileScanner(controller: _controller, onDetect: _alDetectar),
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.amber, width: 3),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 40,
          child: Text('Apunta al código QR de la mesa',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ]),
    );
  }
}
