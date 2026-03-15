// lib/features/scanner/scanner_screen.dart

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/camera_service.dart';
import 'scanner_viewmodel.dart';

// ---------------------------------------------------------------------------
// ScannerScreen
//
// The primary screen of Ki Oushodh. Design decisions:
//   - Camera preview fills the ENTIRE screen — maximum viewfinder for elderly users
//   - Tap anywhere to capture (PRD §4, step 4)
//   - Minimal UI chrome — only essential elements visible during scanning
//   - All state changes produce clear visual + (later) audio feedback
//   - AppLifecycleObserver pauses camera when app backgrounds — saves battery
//     and prevents camera resource locks on low-end devices
// ---------------------------------------------------------------------------
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

  // Pause/resume camera with app lifecycle — critical for battery and resource
  // management on low-end devices
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Full-screen tap target (PRD §4, step 4 + PRD §6 tap targets)
        onTap: () => ref.read(scannerViewModelProvider.notifier).onCaptureTapped(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ----------------------------------------------------------------
            // Layer 1: Camera Preview (full screen)
            // ----------------------------------------------------------------
            _CameraPreviewLayer(
              cameraService: cameraService,
              scanState: scanState,
            ),

            // ----------------------------------------------------------------
            // Layer 2: State-specific overlay UI
            // ----------------------------------------------------------------
            _OverlayLayer(scanState: scanState),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Camera Preview Layer
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
    if (scanState is ScanStateInitializing) {
      return const ColoredBox(color: Colors.black);
    }

    if (scanState is ScanStateError) {
      return const ColoredBox(color: Colors.black);
    }

    final controller = cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }

    // Scale the preview to fill the screen regardless of aspect ratio.
    // This avoids black bars which confuse elderly users — they expect to
    // see what the camera sees, edge to edge.
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
// Overlay Layer — renders different UI depending on state
// ---------------------------------------------------------------------------
class _OverlayLayer extends ConsumerWidget {
  final ScanState scanState;

  const _OverlayLayer({required this.scanState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (scanState) {
      ScanStateInitializing() => const _InitializingOverlay(),
      ScanStateReady()        => const _ReadyOverlay(),
      ScanStateProcessing()   => const _ProcessingOverlay(),
      ScanStateOCRComplete(:final rawText) => _OCRCompleteOverlay(rawText: rawText, ref: ref),
      ScanStateNoTextFound()  => _NoTextOverlay(ref: ref),
      ScanStateError(:final message) => _ErrorOverlay(message: message, ref: ref),
    };
  }
}

// ---------------------------------------------------------------------------
// Individual overlay widgets
// ---------------------------------------------------------------------------

/// Shown while camera is starting up
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
            Text(
              'Starting camera...',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}

/// Camera is live — show a minimal scanning guide
class _ReadyOverlay extends StatelessWidget {
  const _ReadyOverlay();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Top hint bar
          Container(
            width: double.infinity,
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: const Text(
              'Point camera at medicine and tap screen',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Scanning frame guide — helps users aim the camera
          const Spacer(),
          _ScanningFrame(),
          const Spacer(),

          // Bottom tap hint
          Container(
            width: double.infinity,
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: const Text(
              'TAP ANYWHERE TO SCAN',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFFBF00), // Primary amber from AppTheme
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Visual scanning frame guide
class _ScanningFrame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 160,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFFBF00), width: 3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Medicine strip goes here',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

/// Shown while capture + OCR is running
class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFFFFBF00),
              strokeWidth: 6,
            ),
            SizedBox(height: 28),
            Text(
              'Checking...',
              style: TextStyle(
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

/// OCR succeeded — shows raw text and a continue button
/// This will be replaced/extended in Phase 3 when Gemini is wired up
class _OCRCompleteOverlay extends StatelessWidget {
  final String rawText;
  final WidgetRef ref;

  const _OCRCompleteOverlay({required this.rawText, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Text Found:',
              style: TextStyle(
                color: Color(0xFFFFBF00),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  rawText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Phase 3 will replace this with "Identify Medicine" → Gemini call
            ElevatedButton(
              onPressed: () =>
                  ref.read(scannerViewModelProvider.notifier).reset(),
              child: const Text('Scan Again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// No text was found in the image
class _NoTextOverlay extends StatelessWidget {
  final WidgetRef ref;

  const _NoTextOverlay({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.search_off_rounded, color: Colors.white54, size: 72),
            const SizedBox(height: 24),
            const Text(
              'No text found.\nPlease hold the camera closer to the medicine strip.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () =>
                  ref.read(scannerViewModelProvider.notifier).reset(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// An error occurred
class _ErrorOverlay extends StatelessWidget {
  final String message;
  final WidgetRef ref;

  const _ErrorOverlay({required this.message, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFFF5252), size: 72),
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
              onPressed: () =>
                  ref.read(scannerViewModelProvider.notifier).reset(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}