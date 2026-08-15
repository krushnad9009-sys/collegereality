import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'config/router/app_router.dart';
import 'config/theme/app_theme.dart';
import 'config/theme/theme_provider.dart';
import 'core/bootstrap/app_error_handler.dart';
import 'core/bootstrap/firebase_bootstrap.dart';
import 'core/services/crashlytics_service.dart';
import 'features/engagement/services/firebase_messaging_service.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  AppErrorHandler.install();

  // Firebase init failing or hanging (e.g. a stale IndexedDB persistence
  // lock from another browser tab after a hard refresh) must never prevent
  // runApp() from firing — otherwise the native splash never gets removed
  // and the app looks permanently frozen. SplashScreen re-resolves/retries
  // this on its own once the widget tree exists.
  try {
    await FirebaseBootstrap.ensureInitialized();
    await CrashlyticsService.initialize();
  } catch (e, st) {
    debugPrint('Firebase bootstrap failed at startup, continuing: $e\n$st');
  }

  runApp(
    const ProviderScope(
      child: CollegeRealityApp(),
    ),
  );
}

class CollegeRealityApp extends ConsumerWidget {
  const CollegeRealityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final appRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'College Reality',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
