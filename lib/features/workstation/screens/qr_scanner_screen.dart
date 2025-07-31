import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/workstation_model.dart';
import '../services/workstation_storage_service.dart';
import 'workstation_details_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  String? _lastScannedCode;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      
      if (code != null && code != _lastScannedCode) {
        setState(() {
          _isProcessing = true;
          _lastScannedCode = code;
        });

        debugPrint('📱 QR Code scanned: $code');
        await _processScannedCode(code);
        
        // Reset processing after delay
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processScannedCode(String code) async {
    try {
      // Look for workstation by QR code
      WorkstationModel? workstation = WorkstationStorageService.getWorkstationByQR(code);
      
      if (workstation != null) {
        debugPrint('✅ Workstation found: ${workstation.workStation}');
        
        // Show success feedback
        _showScannedFeedback(true, 'Workstation Found!');
        
        // Navigate to workstation details
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkstationDetailsScreen(workstation: workstation),
            ),
          );
        }
      } else {
        debugPrint('❌ No workstation found for QR code: $code');
        _showScannedFeedback(false, 'Workstation not found');
        
        // Check if it's a generic QR code that might match workstation names
        _tryGenericQRMatch(code);
      }
    } catch (e) {
      debugPrint('💥 Error processing scanned code: $e');
      _showScannedFeedback(false, 'Error processing QR code');
    }
  }

  void _tryGenericQRMatch(String code) {
    // Try to match against workstation names or projects
    final allWorkstations = WorkstationStorageService.getAllWorkstations();
    
    for (WorkstationModel workstation in allWorkstations) {
      if (code.toLowerCase().contains(workstation.workStation.toLowerCase()) ||
          code.toLowerCase().contains(workstation.project.toLowerCase())) {
        debugPrint('🔍 Found partial match: ${workstation.workStation}');
        
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkstationDetailsScreen(workstation: workstation),
            ),
          );
        }
        return;
      }
    }
  }

  void _showScannedFeedback(bool success, String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );

    // Haptic feedback
    if (success) {
      // HapticFeedback.lightImpact();
    } else {
      // HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: const Color(0xFF1565C0), // SEWS Blue
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          
          // Overlay with scanning frame
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
            ),
            child: Stack(
              children: [
                // Scanning frame
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isProcessing ? Colors.green : Colors.white,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        // Corner indicators
                        ...List.generate(4, (index) {
                          return Positioned(
                            top: index < 2 ? 0 : null,
                            bottom: index >= 2 ? 0 : null,
                            left: index % 2 == 0 ? 0 : null,
                            right: index % 2 == 1 ? 0 : null,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: index < 2 ? BorderSide(color: _isProcessing ? Colors.green : Colors.white, width: 3) : BorderSide.none,
                                  bottom: index >= 2 ? BorderSide(color: _isProcessing ? Colors.green : Colors.white, width: 3) : BorderSide.none,
                                  left: index % 2 == 0 ? BorderSide(color: _isProcessing ? Colors.green : Colors.white, width: 3) : BorderSide.none,
                                  right: index % 2 == 1 ? BorderSide(color: _isProcessing ? Colors.green : Colors.white, width: 3) : BorderSide.none,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                
                // Instructions
                Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isProcessing 
                              ? 'Processing...' 
                              : 'Point camera at QR code',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_lastScannedCode != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Last scanned: $_lastScannedCode',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      
      // Manual input button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showManualInputDialog,
        backgroundColor: const Color(0xFF4CAF50), // SEWS Green
        icon: const Icon(Icons.keyboard, color: Colors.white),
        label: const Text('Manual Input', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showManualInputDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual QR Code Input'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Enter QR Code or Workstation ID',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) {
                _processScannedCode(controller.text);
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
