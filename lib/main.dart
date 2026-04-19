import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/game_screen.dart';

typedef SeedFactory = int Function();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.seedFactory = defaultSeedFactory});

  final SeedFactory seedFactory;

  static int defaultSeedFactory() {
    return DateTime.now().microsecondsSinceEpoch ^ Random().nextInt(1 << 31);
  }

  @override
  Widget build(BuildContext context) {
    const sand = Color(0xFFD8C29D);
    const moss = Color(0xFF425B45);
    const slate = Color(0xFF1B2730);

    return MaterialApp(
      title: 'Hexfront Prototype',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: moss,
          brightness: Brightness.dark,
          surface: slate,
        ),
        scaffoldBackgroundColor: slate,
        useMaterial3: true,
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(fontSize: 14, height: 1.3, color: sand),
        ),
      ),
      home: GameScreen(seedFactory: seedFactory),
    );
  }
}
