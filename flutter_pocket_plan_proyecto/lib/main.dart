import 'package:flutter/material.dart';
import 'package:flutter_pocket_plan_proyecto/pages/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const IniciarSesion(),
      debugShowCheckedModeBanner: false,
    );
  }
}
