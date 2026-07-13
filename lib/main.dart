import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/router/app_router.dart';
import 'config/theme/app_theme.dart';
import 'config/theme/theme_provider.dart';
import 'core/bootstrap/firebase_bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Start Firebase in the background; splash awaits readiness before routing.
  FirebaseBootstrap.ensureInitialized();
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
