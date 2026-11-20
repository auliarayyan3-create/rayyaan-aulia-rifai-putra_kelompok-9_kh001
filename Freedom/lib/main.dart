import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

// 3 digit terakhir NIM: 113 -> ID User: 1113, ID Admin: 2113
const int kNimLastThreeDigits = 131;

void main() {
  runApp(const PraktikumCrudApp());
}

class PraktikumCrudApp extends StatelessWidget {
  const PraktikumCrudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Praktikum User & Admin CRUD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const MainHomePage(
        nimLastThreeDigits: kNimLastThreeDigits,
      ),
    );
  }
}