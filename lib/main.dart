import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'app/router/app_router.dart';
import 'core/local/local_db.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Open SQLite DB before the widget tree starts
  final db = await LocalDb.open();

  runApp(
    ProviderScope(
      overrides: [
        localDbProvider.overrideWithValue(db),
      ],
      child: const JobyloApp(),
    ),
  );
}

class JobyloApp extends ConsumerWidget {
  const JobyloApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final authState = ref.watch(authStateProvider);

    if (!authState.isLoading) {
      FlutterNativeSplash.remove();
    }

    return MaterialApp.router(
      title: 'Jobylo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
