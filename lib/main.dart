import 'package:flutter/material.dart';
import 'services/quran_data_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Quran360TestApp());
}

class Quran360TestApp extends StatelessWidget {
  const Quran360TestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We fetch Surah 1, Ayah 2 instantly using our service line!
    final String automatedText = QuranDataService.getAyah(surah: 1, ayah: 2);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFBFBFB),
        appBar: AppBar(
          title: const Text('Quran 360 - Database Test'),
          backgroundColor: const Color(0xFF0F5132),
        ),
        body: Center(
          child: Text(
            automatedText, // Automatically displays: الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ
            style: const TextStyle(
              fontSize: 28, 
              fontWeight: FontWeight.bold, 
              color: Colors.black87
            ),
          ),
        ),
      ),
    );
  }
}