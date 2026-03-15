// lib/services/camera_service.dart

import 'package:camera/camera.dart';

// ---------------------------------------------------------------------------
// CameraService
//
// Responsibilities:
//   - Initialize the rear camera at a memory-safe resolution
//   - Provide a CameraController for the preview widget
//   - Capture a single XFile on demand (no streaming)
//   - Dispose cleanly to prevent memory leaks on low-RAM devices
//
// Low-end device decisions:
//   - Resolution capped at medium (720p) — sufficient for OCR, avoids OOM
//   - enableAudio: false — we never need audio, saves resources
//   - imageFormatGroup: jpeg — universally supported, smallest decode overhead
//   - No image streaming — single-shot capture only
// ---------------------------------------------------------------------------
class CameraService {
  CameraController? _controller;
  bool _isInitialized = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  /// Initializes the rear-facing camera.
  ///
  /// Returns normally on success.
  /// Throws a [CameraServiceException] with a user-readable message on failure.
  Future<void> initialize() async {
    // Guard: don't re-initialize if already running
    if (_isInitialized && _controller != null) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw const CameraServiceException('No cameras found on this device.');
      }

      // Always prefer the rear camera for medicine scanning
      final rearCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first, // Fallback for unusual devices
      );

      _controller = CameraController(
        rearCamera,
        // medium = 720p on most devices. Enough for ML Kit text recognition.
        // high (1080p) or veryHigh would use 2-4x more memory for no OCR benefit.
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      // Disable flash by default — elderly users should not be startled
      await _controller!.setFlashMode(FlashMode.off);

      _isInitialized = true;
    } on CameraException catch (e) {
      _isInitialized = false;
      throw CameraServiceException(
        _mapCameraExceptionToMessage(e.code),
      );
    } catch (e) {
      _isInitialized = false;
      throw const CameraServiceException(
          'Camera could not start. Please restart the app.');
    }
  }

  /// Captures a single frame and returns the image file path.
  ///
  /// The caller is responsible for deleting the temp file after OCR is done
  /// to avoid accumulating temp files on low-storage devices.
  Future<String> captureFrame() async {
    if (!_isInitialized || _controller == null) {
      throw const CameraServiceException('Camera is not ready. Please wait.');
    }

    if (_controller!.value.isTakingPicture) {
      throw const CameraServiceException('Already capturing. Please wait.');
    }

    try {
      final XFile file = await _controller!.takePicture();
      return file.path;
    } on CameraException catch (e) {
      throw CameraServiceException(_mapCameraExceptionToMessage(e.code));
    }
  }

  /// Releases all camera resources.
  ///
  /// Must be called when the scanner screen is disposed.
  /// Critical on low-RAM devices — a leaked CameraController will cause
  /// the entire app to be killed by the OS.
  Future<void> dispose() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
      _isInitialized = false;
    }
  }

  /// Pauses the camera preview (e.g., when app goes to background).
  /// Saves CPU and battery on low-end devices.
  Future<void> pause() async {
    if (_isInitialized && _controller != null) {
      try {
        await _controller!.pausePreview();
      } catch (_) {
        // Non-fatal — some devices don't support pause
      }
    }
  }

  /// Resumes the camera preview after pause.
  Future<void> resume() async {
    if (_isInitialized && _controller != null) {
      try {
        await _controller!.resumePreview();
      } catch (_) {
        // Non-fatal
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  String _mapCameraExceptionToMessage(String code) {
    switch (code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        return 'Camera permission is required. Please allow camera access in Settings.';
      case 'AudioAccessDenied':
        // We never request audio, but handle defensively
        return 'Camera could not start. Please restart the app.';
      default:
        return 'Camera error ($code). Please restart the app.';
    }
  }
}

// ---------------------------------------------------------------------------
// Typed exception — allows the ViewModel to catch specifically and
// display a localized error message to the user.
// ---------------------------------------------------------------------------
class CameraServiceException implements Exception {
  final String message;
  const CameraServiceException(this.message);

  @override
  String toString() => 'CameraServiceException: $message';
}