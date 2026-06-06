import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';

/// Full-screen camera view that scans a Pickish session QR and imports it.
class ScanSessionScreen extends StatefulWidget {
  const ScanSessionScreen({Key? key}) : super(key: key);

  @override
  State<ScanSessionScreen> createState() => _ScanSessionScreenState();
}

class _ScanSessionScreenState extends State<ScanSessionScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false; // prevent double-imports from rapid detections

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null || value.isEmpty) continue;

      _handled = true;
      final appState = Provider.of<AppState>(context, listen: false);
      try {
        final name = await appState.importCompactSession(value);
        if (!mounted) return;
        Navigator.pop(context, name); // success: return session name
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid QR: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
          ),
        );
        // Allow scanning again after a short delay.
        await Future.delayed(const Duration(seconds: 2));
        _handled = false;
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Session QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Toggle torch',
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            tooltip: 'Switch camera',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.no_photography,
                          size: 56, color: AppTheme.textMuted),
                      const SizedBox(height: AppConstants.defaultPadding),
                      Text(
                        'Camera unavailable.\n${error.errorDetails?.message ?? 'Check camera permission in Settings.'}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textLight),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Simple framing overlay
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.pastelMint, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Point at a Pickish session QR to import it',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
