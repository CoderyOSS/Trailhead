import 'package:flutter/material.dart';

void main() {
  runApp(const TrailheadApp());
}

class TrailheadApp extends StatelessWidget {
  const TrailheadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trailhead',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF5F7FA),
                Color(0xFFE8ECF1),
              ],
            ),
          ),
          child: SizedBox.expand(),
        ),
      ),
    );
  }
}
