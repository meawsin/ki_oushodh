// lib/main.dart

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
import 'features/settings/settings_screen.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not yet initialized.');
});

// Global navigator key — survives MaterialApp rebuilds
final _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0A0A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  await HiveSetup.registerAdaptersAndOpenBoxes();
  await AppDateUtils.purgeExpiredScanHistory();

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const KiOushodhApp(),
    ),
  );
}

class KiOushodhApp extends ConsumerWidget {
  const KiOushodhApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // High contrast: vivid yellow accent on borders, pure white text
    final darkTheme = settings.highContrast
        ? AppTheme.darkTheme.copyWith(
            colorScheme: AppTheme.darkTheme.colorScheme.copyWith(
              onSurface: Colors.white,
              onSurfaceVariant: Colors.white.withValues(alpha: 0.8),
              // Make borders much more visible
              outline: const Color(0xFFFFBF00),
            ),
          )
        : AppTheme.darkTheme;

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'কি ঔষধ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: darkTheme,
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        final scale = settings.fontScale.clamp(1.0, 1.6);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        );
      },
      home: const ScannerScreen(),
    );
  }
}