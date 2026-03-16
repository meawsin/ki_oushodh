// lib/features/scanner/scanner_screen.dart

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/camera_service.dart';
import '../history/history_screen.dart';
import '../results/results_screen.dart';
import '../settings/settings_screen.dart';
import 'scanner_viewmodel.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _navigating = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
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
    HapticFeedback.mediumImpact();
    Navigator.of(context)
        .push(PageRouteBuilder(
          pageBuilder: (_, a, __) => ResultsScreen(result: resultState.result),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 380),
        ))
        .then((_) => _navigating = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ScanState>(scannerViewModelProvider, (_, next) {
      if (next is ScanStateResult && mounted) {
        _navigateToResults(next);
      }
    });

    final scanState = ref.watch(scannerViewModelProvider);
    final cameraService = ref.watch(cameraServiceProvider);
    final language = ref.watch(languageProvider);
    final isProcessing = scanState is ScanStateProcessing;
    final isReady = scanState is ScanStateReady;
    final hasError = scanState is ScanStateError;
    final noText = scanState is ScanStateNoTextFound;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'কি ঔষধ',
                        style: TextStyle(
                          color: const Color(0xFFFFBF00),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Medicine Identifier',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  _LanguageToggle(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Camera viewfinder — centered, controlled size ──────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Camera feed
                      _buildCameraPreview(cameraService, scanState),

                      // Scanning frame overlay
                      if (isReady) _ScanFrame(pulseAnim: _pulseAnim),

                      // Processing overlay
                      if (isProcessing) const _ProcessingOverlay(),

                      // Error / no text overlay
                      if (hasError || noText)
                        _StatusOverlay(
                          message: scanState is ScanStateError
                              ? scanState.message
                              : (language == 'bn'
                                  ? 'লেখা পাওয়া যায়নি। আরও কাছে ধরুন।'
                                  : 'No text found. Hold closer.'),
                          isError: true,
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Instructions ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFBF00).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.medication_rounded,
                        color: Color(0xFFFFBF00),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            language == 'bn'
                                ? 'ওষুধের স্ট্রিপটি বাক্সে রাখুন'
                                : 'Place medicine strip in frame',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            language == 'bn'
                                ? 'তারপর নিচের বোতামটি চাপুন'
                                : 'Then press the button below',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // ── Scan button ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: isProcessing
                    ? null
                    : () {
                        HapticFeedback.heavyImpact();
                        ref
                            .read(scannerViewModelProvider.notifier)
                            .onCaptureTapped();
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 64,
                  decoration: BoxDecoration(
                    color: isProcessing
                        ? const Color(0xFF2A2A00)
                        : const Color(0xFFFFBF00),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: isProcessing
                        ? []
                        : [
                            BoxShadow(
                              color: const Color(0xFFFFBF00).withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Center(
                    child: isProcessing
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: const Color(0xFFFFBF00).withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                language == 'bn' ? 'দেখা হচ্ছে...' : 'Scanning...',
                                style: TextStyle(
                                  color: const Color(0xFFFFBF00).withValues(alpha: 0.7),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.qr_code_scanner_rounded,
                                color: Color(0xFF1A1A00),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                language == 'bn' ? 'স্ক্যান করুন' : 'Scan Medicine',
                                style: const TextStyle(
                                  color: Color(0xFF1A1A00),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── History + Settings row ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // History
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).push(PageRouteBuilder(
                          pageBuilder: (_, a, __) => const HistoryScreen(),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                          transitionDuration: const Duration(milliseconds: 250),
                        ));
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded,
                                color: Colors.white.withValues(alpha: 0.4),
                                size: 18),
                            const SizedBox(width: 7),
                            Text(
                              language == 'bn' ? 'ইতিহাস' : 'History',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Settings
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).push(PageRouteBuilder(
                        pageBuilder: (_, a, __) => const SettingsScreen(),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                        transitionDuration: const Duration(milliseconds: 250),
                      ));
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Icon(Icons.tune_rounded,
                          color: Colors.white.withValues(alpha: 0.4),
                          size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview(CameraService cameraService, ScanState scanState) {
    final controller = cameraService.controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        scanState is ScanStateInitializing) {
      return Container(
        color: const Color(0xFF141414),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Starting camera...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (scanState is ScanStateError) {
      return Container(
        color: const Color(0xFF141414),
        child: Center(
          child: Icon(
            Icons.camera_alt_outlined,
            color: Colors.white.withValues(alpha: 0.2),
            size: 40,
          ),
        ),
      );
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

// ── Scan frame with animated corners ──────────────────────────────────────
class _ScanFrame extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _ScanFrame({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: pulseAnim,
        builder: (context, _) => Opacity(
          opacity: pulseAnim.value,
          child: Container(
            width: 200,
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFBF00).withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                // Corner accents
                ..._corners(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _corners() {
    const c = Color(0xFFFFBF00);
    const t = 2.5;
    return [
      _corner(top: 0, left: 0,
          border: const Border(top: BorderSide(color: c, width: t), left: BorderSide(color: c, width: t))),
      _corner(top: 0, right: 0,
          border: const Border(top: BorderSide(color: c, width: t), right: BorderSide(color: c, width: t))),
      _corner(bottom: 0, left: 0,
          border: const Border(bottom: BorderSide(color: c, width: t), left: BorderSide(color: c, width: t))),
      _corner(bottom: 0, right: 0,
          border: const Border(bottom: BorderSide(color: c, width: t), right: BorderSide(color: c, width: t))),
    ];
  }

  Widget _corner({double? top, double? left, double? right, double? bottom, required Border border}) {
    return Positioned(
      top: top, left: left, right: right, bottom: bottom,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(border: border),
      ),
    );
  }
}

// ── Processing overlay ─────────────────────────────────────────────────────
class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFFFBF00),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Checking...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status overlay (error/no text) ─────────────────────────────────────────
class _StatusOverlay extends ConsumerWidget {
  final String message;
  final bool isError;
  const _StatusOverlay({required this.message, required this.isError});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.info_outline_rounded : Icons.search_off_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 32,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => ref.read(scannerViewModelProvider.notifier).reset(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFFFBF00), width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(color: Color(0xFFFFBF00), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Language toggle ────────────────────────────────────────────────────────
class _LanguageToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(languageProvider.notifier).toggle();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'বাং',
              style: TextStyle(
                color: language == 'bn' ? const Color(0xFFFFBF00) : Colors.white.withValues(alpha: 0.3),
                fontSize: 13,
                fontWeight: language == 'bn' ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '|',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 12),
              ),
            ),
            Text(
              'EN',
              style: TextStyle(
                color: language == 'en' ? const Color(0xFFFFBF00) : Colors.white.withValues(alpha: 0.3),
                fontSize: 13,
                fontWeight: language == 'en' ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Expose for other screens