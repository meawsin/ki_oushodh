import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/date_utils.dart';
import 'data/local/hive_setup.dart';
import 'features/scanner/scanner_screen.dart';

// ---------------------------------------------------------------------------
// Riverpod provider to make SharedPreferences available app-wide
// ---------------------------------------------------------------------------
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  // Overridden in main() before runApp — see below.
  throw UnimplementedError('SharedPreferences not yet initialized.');
});

// ---------------------------------------------------------------------------
// Entry Point
// ---------------------------------------------------------------------------
Future<void> main() async {
  // Required before any async work in main()
  WidgetsFlutterBinding.ensureInitialized();

  // --- Lock orientation to portrait (ideal for one-handed elderly users) ---
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // --- Initialize Hive for 30-day local scan history ---
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  await HiveSetup.registerAdaptersAndOpenBoxes();

  // --- Run 30-day history cleanup on every app launch ---
  await AppDateUtils.purgeExpiredScanHistory();

  // --- Initialize SharedPreferences (settings & language state) ---
  final sharedPreferences = await SharedPreferences.getInstance();

  // ---------------------------------------------------------------------------
  // runApp — ProviderScope is the top-level wrapper required by Riverpod.
  // We override sharedPreferencesProvider here so it is available
  // synchronously to all child providers without needing a FutureProvider.
  // ---------------------------------------------------------------------------
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const KiOushodhApp(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Root Application Widget
// ---------------------------------------------------------------------------
class KiOushodhApp extends ConsumerWidget {
  const KiOushodhApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In later phases, a settingsProvider will drive themeMode and fontScale.
    // For now we default to dark mode as a high-contrast baseline per the PRD.
    const themeMode = ThemeMode.dark;

    return MaterialApp(
      title: 'কি ঔষধ',
      debugShowCheckedModeBanner: false,

      // --- Theme: High-contrast, large-font foundations (PRD §6) ---
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // --- Accessibility: Large text scaling allowed, but cap to prevent layout breaks ---
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Respect user OS font scale but cap at 1.3x to prevent overflow
            // on critical accessibility UI elements. This will become a
            // user-configurable setting (FR Settings) in a later phase.
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(1.0, 1.3),
            ),
          ),
          child: child!,
        );
      },

      home: const ScannerScreen(),
    );
  }
}