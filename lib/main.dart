import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'features/settings/data/repositories/hive_settings_repository.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/zikr/data/hive_zikr_repository.dart';
import 'features/zikr/presentation/zikr_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Start Flutter immediately. Do not block the first frame with Hive startup.
  runApp(const TasbeehBootstrap());
}

class TasbeehBootstrap extends StatefulWidget {
  const TasbeehBootstrap({super.key});

  @override
  State<TasbeehBootstrap> createState() => _TasbeehBootstrapState();
}

class _TasbeehBootstrapState extends State<TasbeehBootstrap> {
  static const Duration minimumSplashDuration = Duration(seconds: 3);

  late final Future<_BootstrapDependencies> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<_BootstrapDependencies> _bootstrap() async {
    // Initialize the app while the 3-second splash timer runs concurrently.
    final initialization = _initializeApp();

    await Future.wait<void>([
      initialization.then<void>((_) {}),
      Future<void>.delayed(minimumSplashDuration),
    ]);

    return await initialization;
  }

  Future<_BootstrapDependencies> _initializeApp() async {
    await Hive.initFlutter();

    // Version 2 deliberately uses isolated boxes.
    final zikrBox = await Hive.openBox<dynamic>('zikr_v2');
    final sessionBox = await Hive.openLazyBox<dynamic>('zikr_sessions_v2');
    final preferencesBox = await Hive.openBox<dynamic>('preferences_v2');

    final zikrRepository = HiveZikrRepository(zikrBox, sessionBox);

    await zikrRepository.verifyIntegrity();

    return _BootstrapDependencies(
      zikrRepository: zikrRepository,
      settingsRepository: HiveSettingsRepository(preferencesBox),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapDependencies>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StartupError(error: snapshot.error);
        }

        if (!snapshot.hasData) {
          return const _PremiumSplash();
        }

        final dependencies = snapshot.data!;

        return ProviderScope(
          overrides: [
            zikrRepositoryProvider.overrideWithValue(
              dependencies.zikrRepository,
            ),
            settingsRepositoryProvider.overrideWithValue(
              dependencies.settingsRepository,
            ),
          ],
          child: const TasbeehTrackerApp(),
        );
      },
    );
  }
}

class _BootstrapDependencies {
  const _BootstrapDependencies({
    required this.zikrRepository,
    required this.settingsRepository,
  });

  final HiveZikrRepository zikrRepository;
  final HiveSettingsRepository settingsRepository;
}

class _PremiumSplash extends StatelessWidget {
  const _PremiumSplash();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF003B2F),
        body: SizedBox.expand(
          child: Image(
            image: AssetImage('assets/branding/tasbeeh_premium_splash.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF003B2F),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Tasbeeh Management could not start.\n\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFF2D07A), fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
