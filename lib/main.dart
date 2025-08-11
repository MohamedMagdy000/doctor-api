import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دليل الأطباء',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2C5282),
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}
