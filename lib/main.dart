import 'dart:async';

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
  AppErrorHandler.install();

  // Registering the background handler only stores a function reference; a
  // misbehaving plugin registration here must still never abort main()
  // before runApp().
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e, st) {
    debugPrint('[main] FCM background handler registration failed: $e\n$st');
  }

  // Firebase / Crashlytics init is deliberately NOT awaited before
  // runApp(). Firebase.initializeApp() hits the network on web and can be
  // slow or stall (a stale IndexedDB persistence lock from another tab, a
  // blocked CDN); blocking the first frame on it is exactly what leaves
  // the OS splash frozen with nothing rendered behind it. Both the router
  // (via FirebaseInitializingScreen) and SplashScreen re-await
  // FirebaseBootstrap.ensureInitialized() themselves once the widget tree
  // exists, so the UI renders now and catches up when init lands. The
  // chain below is bounded and fully guarded so a stuck platform channel
  // can never surface as an unhandled boot exception.
  unawaited(
    FirebaseBootstrap.ensureInitialized()
        .then((_) => CrashlyticsService.initialize())
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () =>
              debugPrint('[main] boot services still not ready after 20s'),
        )
        .catchError((Object e, StackTrace st) {
          debugPrint('[main] boot services init failed, continuing: $e\n$st');
        }),
  );

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
