import 'package:corextra/corextra.dart';
import 'package:flutter/material.dart';

void main() {
  // Override default breakpoints (optional)
  ResponsiveBreakpoints.setCustomBreakpoints(md: 600, xl: 1200);

  // Enable translation support for validators (optional)
  FormValidators.enableTranslation(true);

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

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // --- corextra utils demo ---
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

    // --- DateTime examples ---
    String? dateStr = '10/08/2023';
    DateTime? dt = dateStr.toTryDateTime(inputFormat: 'dd/MM/yyyy');
    debugPrint('Parsed date: $dt');

    String? isoDate = '2023-08-10T14:00:00Z';
    DateTime? dt2 = isoDate.toTryDateTime();
    debugPrint('Parsed ISO date: $dt2');

    debugPrint('Formatted dt: ${dt.formatDate(outputFormat: 'yyyy-MM-dd')}');
    debugPrint('Formatted dt2: ${dt2.formatDate(outputFormat: 'dd MMM yyyy')}');

    // --- Logging ---
    debugLog('This is an info log');
    debugLog('This is a warning log', level: LogLevel.warning);
    debugLog('This is an error log', level: LogLevel.error);
    AppLogger.logError('Something went wrong while loading data');

    return LayoutBuilder(
      builder: (context, constraints) {
        // --- Example 1: using helpers ---
        String screenSizeLabel;
        if (ResponsiveBreakpoints.isxxl(constraints)) {
          screenSizeLabel = '≥ 2XL Screen';
        } else if (ResponsiveBreakpoints.isXlContext(context)) {
          screenSizeLabel = '≥ XL Screen';
        } else if (ResponsiveBreakpoints.isLg(constraints)) {
          screenSizeLabel = '≥ LG Screen';
        } else if (ResponsiveBreakpoints.isMdContext(context)) {
          screenSizeLabel = '≥ MD Screen';
        } else if (ResponsiveBreakpoints.isSm(constraints)) {
          screenSizeLabel = '≥ SM Screen';
        } else {
          screenSizeLabel = 'Base Screen';
        }

        // --- Example 2: using `when` ---
        final whenLabel = ResponsiveBreakpoints.when(
          constraints,
          base: () => "Base Screen",
          smBuilder: () => "≥ SM Screen",
          mdBuilder: () => "≥ MD Screen",
          lgBuilder: () => "≥ LG Screen",
          xlBuilder: () => "≥ XL Screen",
          xxlBuilder: () => "≥ 2XL Screen",
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Screen size (helpers): $screenSizeLabel',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 10),
              Text(
                'Screen size (when): $whenLabel',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 30),

              // --- Safe setState Example ---
              ElevatedButton(
                onPressed: () {
                  safeSetState(() {
                    message = 'State updated safely at ${DateTime.now()}';
                  });
                },
                child: const Text('Update State Safely'),
              ),
              const SizedBox(height: 20),
              Text(message, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 30),

              // --- Form Validators Demo ---
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: FormValidators.email,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (val) => FormValidators.password(val, minLength: 6),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                ),
                obscureText: true,
                validator: (val) => FormValidators.confirmPassword(
                  val,
                  passwordController.text,
                  minLength: 6,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'OTP'),
                validator: (val) => FormValidators.otp(val, length: 4),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Required Field'),
                validator: FormValidators.required,
              ),
            ],
          ),
        );
      },
    );
  }
}
