// lib/features/scanner/scanner_screen.dart

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/camera_service.dart';
import '../results/results_screen.dart';
import 'scanner_viewmodel.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    final vm = ref.read(scannerViewModelProvider.notifier);
    switch (lifecycleState) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        vm.onAppPaused();
      case AppLifecycleState.resumed:
        vm.onAppResumed();
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scannerViewModelProvider);
    final cameraService = ref.watch(cameraServiceProvider);

    // Route to ResultsScreen when we have a result
    if (scanState is ScanStateResult) {
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultsScreen(result: scanState.result),
          ),
        ).then((_) {
          // When user presses Scan Again and pops back, reset the state
          ref.read(scannerViewModelProvider.notifier).reset();
        });
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => ref.read(scannerViewModelProvider.notifier).onCaptureTapped(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _CameraPreviewLayer(cameraService: cameraService, scanState: scanState),
            _OverlayLayer(scanState: scanState),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Camera Preview
// ---------------------------------------------------------------------------
class _CameraPreviewLayer extends StatelessWidget {
  final CameraService cameraService;
  final ScanState scanState;

  const _CameraPreviewLayer({
    required this.cameraService,
    required this.scanState,
  });

  @override
  Widget build(BuildContext context) {
    if (scanState is ScanStateInitializing || scanState is ScanStateError) {
      return const ColoredBox(color: Colors.black);
    }

    final controller = cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize!.height,
          height: controller.value.previewSize!.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overlay Layer
// ---------------------------------------------------------------------------
class _OverlayLayer extends ConsumerWidget {
  final ScanState scanState;
  const _OverlayLayer({required this.scanState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (scanState) {
      ScanStateInitializing() => const _InitializingOverlay(),
      ScanStateReady()        => const _ReadyOverlay(),
      ScanStateProcessing(:final statusMessage) => _ProcessingOverlay(message: statusMessage),
      ScanStateResult()       => const SizedBox.shrink(), // Navigation handled in parent
      ScanStateNoTextFound()  => _MessageOverlay(
          icon: Icons.search_off_rounded,
          message: 'No text found.\nHold the camera closer to the medicine strip.',
          ref: ref,
        ),
      ScanStateError(:final message) => _MessageOverlay(
          icon: Icons.error_outline_rounded,
          iconColor: const Color(0xFFFF5252),
          message: message,
          ref: ref,
        ),
    };
  }
}

// ---------------------------------------------------------------------------
// Overlay widgets
// ---------------------------------------------------------------------------

class _InitializingOverlay extends StatelessWidget {
  const _InitializingOverlay();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 24),
            Text('Starting...', style: TextStyle(color: Colors.white, fontSize: 20)),
          ],
        ),
      ),
    );
  }
}

class _ReadyOverlay extends ConsumerWidget {
  const _ReadyOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);

    return SafeArea(
      child: Column(
        children: [
          // Language toggle bar at top
          Container(
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('কি ঔষধ',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    Text('EN',
                        style: TextStyle(
                          color: language == 'en' ? const Color(0xFFFFBF00) : Colors.white54,
                          fontWeight: language == 'en' ? FontWeight.w800 : FontWeight.w400,
                          fontSize: 15,
                        )),
                    Switch(
                      value: language == 'bn',
                      onChanged: (_) => ref.read(languageProvider.notifier).toggle(),
                      activeColor: const Color(0xFFFFBF00),
                    ),
                    Text('বাং',
                        style: TextStyle(
                          color: language == 'bn' ? const Color(0xFFFFBF00) : Colors.white54,
                          fontWeight: language == 'bn' ? FontWeight.w800 : FontWeight.w400,
                          fontSize: 15,
                        )),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          // Scan frame guide
          Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFFBF00), width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          const Spacer(),

          // Bottom tap hint
          Container(
            width: double.infinity,
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              language == 'bn' ? 'স্ক্যান করতে ট্যাপ করুন' : 'TAP ANYWHERE TO SCAN',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFBF00),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  final String message;
  const _ProcessingOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFFFFBF00),
              strokeWidth: 6,
            ),
            const SizedBox(height: 28),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageOverlay extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String message;
  final WidgetRef ref;

  const _MessageOverlay({
    required this.icon,
    this.iconColor = Colors.white54,
    required this.message,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);

    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, color: iconColor, size: 72),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => ref.read(scannerViewModelProvider.notifier).reset(),
              child: Text(language == 'bn' ? 'আবার চেষ্টা করুন' : 'Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}