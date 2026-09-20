import 'package:flutter/material.dart';

class FameverseApp extends StatelessWidget {
  const FameverseApp({super.key});

  static const nativeProbeKey = Key('fameverse-native-probe');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fameverse Live',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FAMEVERSE LIVE',
                  key: nativeProbeKey,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Native pipeline probe',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
