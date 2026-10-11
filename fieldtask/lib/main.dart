import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'data/local/local_storage.dart';
import 'presentation/blocs/auth_cubit.dart';
import 'presentation/blocs/intervention_cubit.dart';
import 'presentation/blocs/sync_cubit.dart';
import 'presentation/pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Chrome : SQLite via WebAssembly (sans web worker, plus simple)
    // Windows / Linux / macOS : SQLite via FFI   (Android / iOS : natif)
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWebNoWebWorker;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    await LocalStorage.instance.init();
    await NotificationService.instance.init();
  } catch (e, st) {
    // Affiche l'erreur au lieu d'un ecran blanc
    debugPrint('ERREUR AU DEMARRAGE: $e\n$st');
    runApp(_StartupError('$e'));
    return;
  }
  runApp(const FieldTaskApp());
}

class _StartupError extends StatelessWidget {
  final String message;
  const _StartupError(this.message);

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: SelectableText(
                'Erreur au demarrage de la base de donnees :\n\n$message',
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ),
        ),
      );
}

class FieldTaskApp extends StatelessWidget {
  const FieldTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivity = ConnectivityService();
    connectivity.init();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()..checkSession()),
        BlocProvider(create: (_) => InterventionCubit()..load()),
        BlocProvider(
          create: (ctx) => SyncCubit(
            connectivity: connectivity,
            onSynced: () => ctx.read<InterventionCubit>().load(pull: false),
          )..start(),
        ),
      ],
      child: MaterialApp(
        title: 'FieldTask Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashPage(),
      ),
    );
  }
}
