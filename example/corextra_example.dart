import 'package:corextra/corextra.dart';
import 'package:flutter/material.dart';

void main() {
  // Override default breakpoints (optional)
  ResponsiveBreakpoints.setCustomBreakpoints(xsMax: 500, mdMax: 1100);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'corextra Demo',
      home: Scaffold(
        appBar: AppBar(title: const Text('corextra Demo')),
        body: const DemoScreen(),
      ),
    );
  }
}

class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Examples of corextra utilities:
    debugPrint('${'123'.toTryInt()}'); // 123
    debugPrint('${'3.14'.toTryDouble()}'); // 3.14
    debugPrint('${'true'.toTryBool()}'); // true
    debugPrint('hello world'.capitalize()); // Hello World

    List<int>? items;
    debugPrint('${items.isNullOrEmpty}'); // true
    debugPrint('${[1, 2, 3].isNotNullOrEmpty}'); // true

    debugPrint('${(-5).toZeroIfNegative()}'); // 0
    debugPrint('${(-3.5).toZeroIfNegative()}'); // 0.0

    debugPrint('${isStringEmpty(null)}'); // true
    debugPrint('${isListEmpty([1, 2])}'); // false

    return LayoutBuilder(
      builder: (context, constraints) {
        String screenSizeLabel;

        if (ResponsiveBreakpoints.isXS(constraints)) {
          screenSizeLabel = 'Extra Small Screen';
        } else if (ResponsiveBreakpoints.isSMContext(context)) {
          screenSizeLabel = 'Small Screen';
        } else if (ResponsiveBreakpoints.isMD(constraints)) {
          screenSizeLabel = 'Medium Screen';
        } else if (ResponsiveBreakpoints.isLGContext(context)) {
          screenSizeLabel = 'Large Screen';
        } else if (ResponsiveBreakpoints.isXL(constraints)) {
          screenSizeLabel = 'Extra Large Screen';
        } else {
          screenSizeLabel = 'XXL or larger Screen';
        }

        return Center(
          child: Text(
            'Screen size: $screenSizeLabel',
            style: const TextStyle(fontSize: 24),
          ),
        );
      },
    );
  }
}
