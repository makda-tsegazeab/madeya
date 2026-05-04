import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class WorkerQrScannerPage extends StatefulWidget {
  const WorkerQrScannerPage({super.key});

  @override
  State<WorkerQrScannerPage> createState() => _WorkerQrScannerPageState();
}

class _WorkerQrScannerPageState extends State<WorkerQrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _hasReturned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _returnCode(String code) {
    if (_hasReturned) return;
    _hasReturned = true;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1621),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1621),
        foregroundColor: Colors.white,
        title: const Text(
          'Scan QR token',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Torch',
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flash_on),
          ),
          IconButton(
            tooltip: 'Switch camera',
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final raw = barcodes.first.rawValue;
              if (raw == null) return;
              final code = raw.trim();
              if (code.isEmpty) return;
              _returnCode(code);
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
              ),
              child: const Text(
                'Point the camera at the customer QR code.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

