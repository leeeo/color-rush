import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_colors.dart';
import 'core/prefs.dart';
import 'monetization/ads_manager.dart';
import 'monetization/iap_manager.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Prefs.init();
  runApp(const ColorRushApp());
  // Ads (UMP consent + ATT + SDK) and IAP init happen after the first frame
  // so a slow network never blocks app startup. Both never throw.
  unawaited(AdsManager.instance.init());
  unawaited(IapManager.instance.init());
}

class ColorRushApp extends StatelessWidget {
  const ColorRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Rush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.green,
          brightness: Brightness.dark,
          surface: AppColors.surface,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ko')],
      home: const HomeScreen(),
    );
  }
}
