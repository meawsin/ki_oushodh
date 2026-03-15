// lib/features/scanner/scanner_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/camera_service.dart';
import '../../services/ocr_service.dart';

// ---------------------------------------------------------------------------
// Scan State — sealed class representing every possible state of the scanner
// ---------------------------------------------------------------------------
sealed class ScanState {
  const ScanState();
}

/// Camera is initializing
class ScanStateInitializing extends ScanState {
  const ScanStateInitializing();
}

/// Camera is live, waiting for user to tap
class ScanStateReady extends ScanState {
  const ScanStateReady();
}

/// User tapped — capture + OCR in progress
class ScanStateProcessing extends ScanState {
  const ScanStateProcessing();
}

/// OCR succeeded — raw text extracted, ready for LLM (Phase 3)
class ScanStateOCRComplete extends ScanState {
  final String rawText;
  const ScanStateOCRComplete(this.rawText);
}

/// Empty scan — camera captured but no text detected in the image
class ScanStateNoTextFound extends ScanState {
  const ScanStateNoTextFound();
}

/// Something went wrong — message is user-readable and will be spoken by TTS
class ScanStateError extends ScanState {
  final String message;
  const ScanStateError(this.message);
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Provides the CameraService as a singleton scoped to the scanner feature.
/// Auto-disposed when the scanner screen leaves the tree — frees camera on
/// low-RAM devices immediately.
final cameraServiceProvider = Provider.autoDispose<CameraService>((ref) {
  final service = CameraService();
  // Dispose the camera when this provider is no longer needed
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provides the OCRService. Stateless, so a simple provider is fine.
final ocrServiceProvider = Provider<OCRService>((ref) => OCRService());

/// The main ViewModel provider for the scanner screen.
final scannerViewModelProvider =
    NotifierProvider.autoDispose<ScannerViewModel, ScanState>(
  ScannerViewModel.new,
);

// ---------------------------------------------------------------------------
// ScannerViewModel
// ---------------------------------------------------------------------------
class ScannerViewModel extends AutoDisposeNotifier<ScanState> {
  late final CameraService _cameraService;
  late final OCRService _ocrService;

  @override
  ScanState build() {
    _cameraService = ref.read(cameraServiceProvider);
    _ocrService = ref.read(ocrServiceProvider);

    // Kick off camera initialization as soon as the ViewModel is created
    _initializeCamera();

    return const ScanStateInitializing();
  }

  // ---------------------------------------------------------------------------
  // Public API (called by ScannerScreen)
  // ---------------------------------------------------------------------------

  /// Called when the user taps anywhere on the camera viewfinder.
  Future<void> onCaptureTapped() async {
    // Ignore taps while already processing or initializing
    if (state is! ScanStateReady) return;

    state = const ScanStateProcessing();

    try {
      // Step 1: Capture a single frame
      final imagePath = await _cameraService.captureFrame();

      // Step 2: Run on-device OCR
      final rawText = await _ocrService.extractText(imagePath);

      // Step 3: Evaluate result
      if (rawText.trim().isEmpty) {
        state = const ScanStateNoTextFound();
      } else {
        // Hand off to LLM in Phase 3
        state = ScanStateOCRComplete(rawText);
      }
    } on CameraServiceException catch (e) {
      state = ScanStateError(e.message);
    } on OCRServiceException catch (e) {
      state = ScanStateError(e.message);
    } catch (e) {
      state = const ScanStateError(
        'Something went wrong. Please try again.',
      );
    }
  }

  /// Resets the scanner back to ready state (the "Scan Again" action).
  void reset() {
    if (state is ScanStateReady) return; // Already ready
    state = const ScanStateReady();
  }

  /// Called by the screen on app lifecycle changes (pause/resume).
  Future<void> onAppPaused() => _cameraService.pause();
  Future<void> onAppResumed() => _cameraService.resume();

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initialize();
      state = const ScanStateReady();
    } on CameraServiceException catch (e) {
      state = ScanStateError(e.message);
    }
  }
}