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

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  String message = 'Initial State';

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

    // DateTime extension examples:
    String? dateStr = '10/08/2023';
    DateTime? dt = dateStr.toTryDateTime(inputFormat: 'dd/MM/yyyy');
    debugPrint('Parsed date: $dt');

    String? isoDate = '2023-08-10T14:00:00Z';
    DateTime? dt2 = isoDate.toTryDateTime();
    debugPrint('Parsed ISO date: $dt2');

    debugPrint('Formatted dt: ${dt.formatDate(outputFormat: 'yyyy-MM-dd')}');
    debugPrint('Formatted dt2: ${dt2.formatDate(outputFormat: 'dd MMM yyyy')}');

    // --- Using debugLog for structured debug output ---
    debugLog('This is an info log');
    debugLog('This is a warning log', level: LogLevel.warning);
    debugLog('This is an error log', level: LogLevel.error);

    // --- Using AppLogger to log an error ---
    AppLogger.logError('Something went wrong while loading data');

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

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Screen size: $screenSizeLabel',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // --- Using safeSetState to avoid setState on disposed widget ---
                safeSetState(() {
                  message = 'State updated safely at ${DateTime.now()}';
                });
              },
              child: const Text('Update State Safely'),
            ),
            const SizedBox(height: 20),
            Text(message, style: const TextStyle(fontSize: 18)),
          ],
        );
      },
    );
  }
}
