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
  bool _navigating = false; // Guard against double navigation

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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final vm = ref.read(scannerViewModelProvider.notifier);
    switch (state) {
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

  void _navigateToResults(ScanStateResult resultState) {
    if (_navigating) return;
    _navigating = true;

    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => ResultsScreen(result: resultState.result),
        ))
        .then((_) => _navigating = false);
    // ResultsScreen's PopScope handles reset() on pop
  }

  @override
  Widget build(BuildContext context) {
    // Listen for result state and navigate — cleaner than addPostFrameCallback
    ref.listen<ScanState>(scannerViewModelProvider, (_, next) {
      if (next is ScanStateResult && mounted) {
        _navigateToResults(next);
      }
    });

    final scanState = ref.watch(scannerViewModelProvider);
    final cameraService = ref.watch(cameraServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () =>
            ref.read(scannerViewModelProvider.notifier).onCaptureTapped(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _CameraPreviewLayer(
                cameraService: cameraService, scanState: scanState),
            _OverlayLayer(scanState: scanState),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _CameraPreviewLayer extends StatelessWidget {
  final CameraService cameraService;
  final ScanState scanState;

  const _CameraPreviewLayer(
      {required this.cameraService, required this.scanState});

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
class _OverlayLayer extends ConsumerWidget {
  final ScanState scanState;
  const _OverlayLayer({required this.scanState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (scanState) {
      ScanStateInitializing() => const _InitializingOverlay(),
      ScanStateReady()        => const _ReadyOverlay(),
      ScanStateProcessing(:final statusMessage) =>
          _ProcessingOverlay(message: statusMessage),
      ScanStateResult()       => const SizedBox.shrink(),
      ScanStateNoTextFound()  => _MessageOverlay(
          icon: Icons.search_off_rounded,
          message: 'No text found.\nHold camera closer to the medicine.',
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
class _InitializingOverlay extends StatelessWidget {
  const _InitializingOverlay();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 24),
              Text('Starting camera...',
                  style: TextStyle(color: Colors.white, fontSize: 20)),
            ],
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
class _ReadyOverlay extends ConsumerWidget {
  const _ReadyOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);

    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Container(
            color: Colors.black54,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('কি ঔষধ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                _ScannerLanguageToggle(),
              ],
            ),
          ),
          const Spacer(),

          // Scan frame
          Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: 160,
            decoration: BoxDecoration(
              border:
                  Border.all(color: const Color(0xFFFFBF00), width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const Spacer(),

          // Bottom hint
          Container(
            width: double.infinity,
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              language == 'bn'
                  ? 'স্ক্যান করতে যেকোনো জায়গায় ট্যাপ করুন'
                  : 'TAP ANYWHERE TO SCAN',
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

// Language toggle for scanner (dark background version)
class _ScannerLanguageToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('EN',
            style: TextStyle(
              color: language == 'en'
                  ? const Color(0xFFFFBF00)
                  : Colors.white54,
              fontWeight: language == 'en'
                  ? FontWeight.w800
                  : FontWeight.w400,
              fontSize: 15,
            )),
        Switch(
          value: language == 'bn',
          onChanged: (_) =>
              ref.read(languageProvider.notifier).toggle(),
          activeColor: const Color(0xFFFFBF00),
        ),
        Text('বাং',
            style: TextStyle(
              color: language == 'bn'
                  ? const Color(0xFFFFBF00)
                  : Colors.white54,
              fontWeight: language == 'bn'
                  ? FontWeight.w800
                  : FontWeight.w400,
              fontSize: 15,
            )),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
class _ProcessingOverlay extends StatelessWidget {
  final String message;
  const _ProcessingOverlay({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                  color: Color(0xFFFFBF00), strokeWidth: 6),
              const SizedBox(height: 28),
              Text(message,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
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
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.5)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () =>
                  ref.read(scannerViewModelProvider.notifier).reset(),
              child: Text(language == 'bn'
                  ? 'আবার চেষ্টা করুন'
                  : 'Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}