import 'package:flutter/material.dart';
import 'ui/recitation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Quran360App());
}

class Quran360App extends StatelessWidget {
  const Quran360App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran 360',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF0F5132),
        scaffoldBackgroundColor: const Color(0xFFFBFBFB),
      ),
      home: const RecitationPracticeScreen(),
    );
  }
}