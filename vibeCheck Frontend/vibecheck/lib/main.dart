import 'package:flutter/material.dart';
import 'analyze_screen.dart';

void main() {
  runApp(VibeCheckApp());
}

class VibeCheckApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeCheck',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: AnalyzeScreen(),
    );
  }
}