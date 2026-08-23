import 'package:corextra/corextra.dart';
import 'package:flutter/material.dart';

import 'screens/demo_screen.dart';

class MyDemoApp extends StatelessWidget {
  const MyDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Corextra Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      builder: (context, child) {
        return CorextraDevToolsOverlay(
          enabled: true, // Explicitly enabled for demo
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const DemoScreen(),
    );
  }
}
