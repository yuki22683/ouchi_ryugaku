import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: OuchiRyugakuApp(),
    ),
  );
}

class OuchiRyugakuApp extends StatelessWidget {
  const OuchiRyugakuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'おうち留学',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Noto Sans JP', // Assuming the font might be available or fallback to system
      ),
      home: const HomeScreen(),
    );
  }
}
