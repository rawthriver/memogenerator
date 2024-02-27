import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:memogenerator/presentation/main/main_page.dart';

void main() async => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    EquatableConfig.stringify = true;
    return const MaterialApp(
      home: MainPage(),
    );
  }
}
