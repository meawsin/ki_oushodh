// lib/domain/models/scan_result.dart

// ---------------------------------------------------------------------------
// ScanResult
//
// Immutable value object returned by LLMService.
// Keeping name and summary separate lets the UI render them at different
// font sizes — medicine name large, summary slightly smaller (PRD §6).
// ---------------------------------------------------------------------------
class ScanResult {
  final String medicineName;
  final String summary;
  final String language; // 'en' or 'bn'

  const ScanResult({
    required this.medicineName,
    required this.summary,
    required this.language,
  });

  /// The full spoken string passed to TTSService.
  /// Combines name + summary into one natural sentence for audio playback.
  String get spokenText => '$medicineName. $summary';

  @override
  String toString() =>
      'ScanResult(name: $medicineName, lang: $language)';
}