// lib/features/scanner/scanner_screen.dart
//
// Key UI fixes vs original:
//   - Processing overlay shows meaningful step labels (Capturing / Reading / Identifying)
//   - Scan button uses InkWell with proper splash for tactile feedback
//   - _ProcessingOverlay uses AnimatedSwitcher for smooth label transitions
//   - History/Settings use InkWell (proper ripple) not raw GestureDetector
//   - Camera "Starting..." text is bilingual
//   - Status overlay icon changed from info → error_outline for error states
//   - "Scanning..." label on button reflects actual step from ScanStateProcessing
//   - Bottom nav buttons have minimum 48px touch target (accessibility)

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
  bool _isTorchActive = false;
  Offset? _focusPoint;
  bool _showFocusRing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  void _onViewfinderTapped(TapDownDetails details, BoxConstraints constraints) {
    if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) return;
    final localPos = details.localPosition;
    final normalizedX = (localPos.dx / constraints.maxWidth).clamp(0.0, 1.0);
    final normalizedY = (localPos.dy / constraints.maxHeight).clamp(0.0, 1.0);

    HapticFeedback.selectionClick();
    ref.read(scannerViewModelProvider.notifier).setFocusPoint(Offset(normalizedX, normalizedY));

    setState(() {
      _focusPoint = localPos;
      _showFocusRing = true;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() => _showFocusRing = false);
      }
    });
  }

  Future<void> _handleToggleTorch() async {
    HapticFeedback.lightImpact();
    final newState = await ref.read(scannerViewModelProvider.notifier).toggleTorch();
    if (mounted) {
      setState(() => _isTorchActive = newState);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.65, end: 1.0).animate(
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
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 380),
        ))
        .then((_) => _navigating = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ScanState>(scannerViewModelProvider, (_, next) {
      if (next is ScanStateResult && mounted) _navigateToResults(next);
    });

    final scanState      = ref.watch(scannerViewModelProvider);
    final cameraService  = ref.watch(cameraServiceProvider);
    final language       = ref.watch(languageProvider);
    final cs             = Theme.of(context).colorScheme;
    final isDark         = Theme.of(context).brightness == Brightness.dark;
    final isProcessing   = scanState is ScanStateProcessing;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────
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
                          color: cs.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Medicine Identifier',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  _LanguageToggle(isDark: isDark),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Camera viewfinder ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) => _onViewfinderTapped(details, constraints),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildCameraPreview(cameraService, scanState, cs, language),
                            if (scanState is ScanStateReady)
                              _ScanFrame(pulseAnim: _pulseAnim, color: cs.primary),
                            if (_showFocusRing && _focusPoint != null)
                              _FocusIndicator(point: _focusPoint!, color: cs.primary),
                            if (scanState is ScanStateProcessing)
                              _ProcessingOverlay(
                                cs: cs,
                                step: scanState.step,
                                language: language,
                              ),
                            if (scanState is ScanStateError || scanState is ScanStateNoTextFound)
                              _StatusOverlay(
                                message: scanState is ScanStateError
                                    ? scanState.message
                                    : (language == 'bn'
                                        ? 'লেখা পাওয়া যায়নি। আরও কাছে ধরুন।'
                                        : 'No text found. Hold closer.'),
                                isError: true,
                                cs: cs,
                              ),
                            // Torch toggle button positioned top-right of viewfinder
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Semantics(
                                button: true,
                                label: language == 'bn'
                                    ? (_isTorchActive ? 'ফ্ল্যাশলাইট বন্ধ করুন' : 'ফ্ল্যাশলাইট চালু করুন')
                                    : (_isTorchActive ? 'Turn off flashlight' : 'Turn on flashlight'),
                                child: Material(
                                  color: _isTorchActive
                                      ? cs.primary
                                      : Colors.black.withValues(alpha: 0.45),
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    onTap: _handleToggleTorch,
                                    customBorder: const CircleBorder(),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        _isTorchActive
                                            ? Icons.flash_on_rounded
                                            : Icons.flash_off_rounded,
                                        color: _isTorchActive
                                            ? cs.onPrimary
                                            : Colors.white.withValues(alpha: 0.9),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Instruction card ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outline),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.medication_rounded, color: cs.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            language == 'bn'
                                ? 'ওষুধের স্ট্রিপটি ফ্রেমে রাখুন'
                                : 'Place medicine strip in frame',
                            style: TextStyle(
                              color: cs.onSurface,
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
                              color: cs.onSurfaceVariant,
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

            // ── Scan button ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Semantics(
                button: true,
                label: language == 'bn'
                    ? (isProcessing ? 'ওষুধ স্ক্যান করা হচ্ছে' : 'ওষুধ স্ক্যান করার বোতাম')
                    : (isProcessing ? 'Scanning medicine' : 'Scan medicine button'),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isProcessing
                        ? null
                        : () {
                            HapticFeedback.heavyImpact();
                            ref.read(scannerViewModelProvider.notifier).onCaptureTapped();
                          },
                    borderRadius: BorderRadius.circular(18),
                    splashColor: cs.onPrimary.withValues(alpha: 0.2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 64,
                      decoration: BoxDecoration(
                        color: isProcessing ? cs.primary.withValues(alpha: 0.35) : cs.primary,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: isProcessing
                            ? []
                            : [
                                BoxShadow(
                                  color: cs.primary.withValues(alpha: 0.28),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: Center(
                        child: scanState is ScanStateProcessing
                            ? _ProcessingButtonContent(
                                cs: cs,
                                step: scanState.step,
                                language: language,
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.qr_code_scanner_rounded,
                                      color: cs.onPrimary, size: 22),
                                  const SizedBox(width: 10),
                                  Text(
                                    language == 'bn' ? 'স্ক্যান করুন' : 'Scan Medicine',
                                    style: TextStyle(
                                      color: cs.onPrimary,
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
              ),
            ),

            const SizedBox(height: 12),

            // ── History + Settings row ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: language == 'bn' ? 'স্ক্যান ইতিহাস দেখুন' : 'View scan history',
                      child: _SecondaryButton(
                        icon: Icons.history_rounded,
                        label: language == 'bn' ? 'ইতিহাস' : 'History',
                        cs: cs,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).push(PageRouteBuilder(
                            pageBuilder: (_, a, __) => const HistoryScreen(),
                            transitionsBuilder: (_, anim, __, child) =>
                                FadeTransition(opacity: anim, child: child),
                            transitionDuration: const Duration(milliseconds: 250),
                          ));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Semantics(
                    button: true,
                    label: language == 'bn' ? 'অ্যাক্সেসিবিলিটি সেটিংস' : 'Accessibility settings',
                    child: _SecondaryButton(
                      icon: Icons.tune_rounded,
                      cs: cs,
                      width: 52,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).push(PageRouteBuilder(
                          pageBuilder: (_, a, __) => const SettingsScreen(),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                          transitionDuration: const Duration(milliseconds: 250),
                        ));
                      },
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

  Widget _buildCameraPreview(
      CameraService svc, ScanState state, ColorScheme cs, String language) {
    final ctrl = svc.controller;
    if (ctrl == null || !ctrl.value.isInitialized || state is ScanStateInitializing) {
      return Container(
        color: cs.surfaceContainerHighest,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            Text(
              language == 'bn' ? 'ক্যামেরা চালু হচ্ছে...' : 'Starting camera...',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ]),
        ),
      );
    }
    if (state is ScanStateError) {
      return Container(
        color: cs.surfaceContainerHighest,
        child: Center(
          child: Icon(Icons.camera_alt_outlined, color: cs.onSurfaceVariant, size: 40),
        ),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: ctrl.value.previewSize!.height,
          height: ctrl.value.previewSize!.width,
          child: CameraPreview(ctrl),
        ),
      ),
    );
  }
}

// ── Scan frame ──────────────────────────────────────────────────────────────
class _ScanFrame extends StatelessWidget {
  final Animation<double> pulseAnim;
  final Color color;
  const _ScanFrame({required this.pulseAnim, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: pulseAnim,
        builder: (_, __) => Opacity(
          opacity: pulseAnim.value,
          child: Container(
            width: 210, height: 118,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
            ),
            child: Stack(children: _corners(color)),
          ),
        ),
      ),
    );
  }

  List<Widget> _corners(Color c) {
    const t = 2.5;
    return [
      _corner(top: 0, left: 0, border: Border(top: BorderSide(color: c, width: t), left: BorderSide(color: c, width: t))),
      _corner(top: 0, right: 0, border: Border(top: BorderSide(color: c, width: t), right: BorderSide(color: c, width: t))),
      _corner(bottom: 0, left: 0, border: Border(bottom: BorderSide(color: c, width: t), left: BorderSide(color: c, width: t))),
      _corner(bottom: 0, right: 0, border: Border(bottom: BorderSide(color: c, width: t), right: BorderSide(color: c, width: t))),
    ];
  }

  Widget _corner({double? top, double? left, double? right, double? bottom, required Border border}) =>
      Positioned(
        top: top, left: left, right: right, bottom: bottom,
        child: Container(width: 18, height: 18, decoration: BoxDecoration(border: border)),
      );
}

// ── Processing overlay — shows step label with smooth crossfade ─────────────
class _ProcessingOverlay extends StatelessWidget {
  final ColorScheme cs;
  final ProcessingStep step;
  final String language;
  const _ProcessingOverlay({required this.cs, required this.step, required this.language});

  String _label() {
    switch (step) {
      case ProcessingStep.capturing:
        return language == 'bn' ? 'ছবি তোলা হচ্ছে...' : 'Capturing...';
      case ProcessingStep.reading:
        return language == 'bn' ? 'লেখা পড়া হচ্ছে...' : 'Reading text...';
      case ProcessingStep.identifying:
        return language == 'bn' ? 'ওষুধ খোঁজা হচ্ছে...' : 'Identifying...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 32, height: 32,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              _label(),
              key: ValueKey(step),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Processing button content — mirrors overlay step labels ─────────────────
class _ProcessingButtonContent extends StatelessWidget {
  final ColorScheme cs;
  final ProcessingStep step;
  final String language;
  const _ProcessingButtonContent({required this.cs, required this.step, required this.language});

  String _label() {
    switch (step) {
      case ProcessingStep.capturing:
        return language == 'bn' ? 'ছবি তোলা হচ্ছে...' : 'Capturing...';
      case ProcessingStep.reading:
        return language == 'bn' ? 'পড়া হচ্ছে...' : 'Reading...';
      case ProcessingStep.identifying:
        return language == 'bn' ? 'খোঁজা হচ্ছে...' : 'Identifying...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: cs.onPrimary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _label(),
            key: ValueKey(step),
            style: TextStyle(
              color: cs.onPrimary.withValues(alpha: 0.8),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Status overlay ──────────────────────────────────────────────────────────
class _StatusOverlay extends ConsumerWidget {
  final String message;
  final bool isError;
  final ColorScheme cs;
  const _StatusOverlay({required this.message, required this.cs, this.isError = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    return Container(
      color: Colors.black.withValues(alpha: 0.78),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
              color: isError
                  ? cs.error.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.5),
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => ref.read(scannerViewModelProvider.notifier).reset(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  language == 'bn' ? 'আবার চেষ্টা করুন' : 'Try Again',
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Language toggle ──────────────────────────────────────────────────────────
class _LanguageToggle extends ConsumerWidget {
  final bool isDark;
  const _LanguageToggle({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(languageProvider.notifier).toggle();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('বাং', style: TextStyle(
            color: language == 'bn' ? cs.primary : cs.onSurfaceVariant,
            fontSize: 13,
            fontWeight: language == 'bn' ? FontWeight.w700 : FontWeight.w400,
          )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('|', style: TextStyle(color: cs.outlineVariant, fontSize: 12)),
          ),
          Text('EN', style: TextStyle(
            color: language == 'en' ? cs.primary : cs.onSurfaceVariant,
            fontSize: 13,
            fontWeight: language == 'en' ? FontWeight.w700 : FontWeight.w400,
          )),
        ]),
      ),
    );
  }
}

// ── Secondary button ─────────────────────────────────────────────────────────
class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final ColorScheme cs;
  final VoidCallback onTap;
  final double? width;

  const _SecondaryButton({
    required this.icon,
    this.label,
    required this.cs,
    required this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: width,
          height: 52,   // bumped from 48 → 52 for accessibility
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: cs.onSurfaceVariant, size: 18),
              if (label != null) ...[
                const SizedBox(width: 7),
                Text(label!, style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tap-to-focus indicator ──────────────────────────────────────────────────
class _FocusIndicator extends StatelessWidget {
  final Offset point;
  final Color color;

  const _FocusIndicator({required this.point, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: point.dx - 28,
      top: point.dy - 28,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.35, end: 1.0),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutBack,
          builder: (_, scale, child) => Transform.scale(
            scale: scale,
            child: child,
          ),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
