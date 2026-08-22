import 'package:corextra/corextra.dart';
import 'package:dio/dio.dart';
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // Wrap with CorextraDevToolsOverlay to get a floating in-app
      // inspector (Network / Logs / Performance / Info tabs). Tap the
      // bubble in the corner to open it.
      builder: (context, child) =>
          CorextraDevToolsOverlay(child: child ?? const SizedBox.shrink()),
      home: const DemoScreen(),
    );
  }
}

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  String stateMessage = 'Initial state';
  bool showAnimatedText = false;

  late final Dio dio;

  @override
  void initState() {
    super.initState();
    // httpbin.org is a small public service built exactly for this: it
    // lets you request a specific status code and echoes back whatever
    // you send it, which is handy for exercising every DevTools Network
    // tab case (2xx / 4xx / 5xx, request body, response body, headers).
    dio = Dio(BaseOptions(baseUrl: 'https://httpbin.org'));
    dio.interceptors.add(const AppLoggerInterceptor());
    // Additive: also feeds the DevTools panel's Network tab.
    // `hiddenHeaders` redacts sensitive values (e.g. auth tokens) before
    // they're stored, so they never show up in the panel.
    dio.interceptors.add(
      const CorextraDevToolsInterceptor(hiddenHeaders: {'authorization'}),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    dio.close();
    super.dispose();
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }

  // --- GET 200: a plain successful request, to see a full response body —
  // and, with a few query parameters attached, the Network tab's
  // "Query Parameters" block (pretty-printed, with its own copy button,
  // right above the request headers). ---
  Future<void> _sendGet200() async {
    _notify('GET 200 sent — check the Network tab');
    try {
      await dio.get(
        '/get',
        queryParameters: {'demo': 'corextra', 'page': '2', 'sort': 'desc'},
      );
    } on DioException {
      // Not expected to fail, but surfaced in the Network tab either way.
    }
  }

  // --- POST with a body: exercises request body + header capture (and
  // header redaction — the Authorization header is hidden in the panel).
  // httpbin echoes the request back inside the response body, so you can
  // compare both side by side in the expanded row. ---
  Future<void> _sendPostWithBody() async {
    _notify('POST sent — check the request/response body in the Network tab');
    try {
      await dio.post(
        '/post',
        data: {'name': 'corextra', 'feature': 'DevTools'},
        options: Options(headers: {'Authorization': 'Bearer secret-token'}),
      );
    } on DioException {
      // Not expected to fail, but surfaced in the Network tab either way.
    }
  }

  // --- GET 400: a client error status, with a real (empty) response. ---
  Future<void> _sendGet400() async {
    _notify('GET 400 sent — check the Network tab');
    try {
      await dio.get('/status/400');
    } on DioException {
      // Expected — dio treats non-2xx as an error; shows up red, status 400.
    }
  }

  // --- GET 500: a server error status. ---
  Future<void> _sendGet500() async {
    _notify('GET 500 sent — check the Network tab');
    try {
      await dio.get('/status/500');
    } on DioException {
      // Expected — shows up red, status 500.
    }
  }

  // --- Network error: no response at all (DNS/connection failure),
  // as opposed to the 400/500 cases above which do get a response. ---
  Future<void> _sendNetworkError() async {
    _notify('Sending a request that will fail to connect — check the '
        'Network tab');
    final failingDio = Dio(
      BaseOptions(baseUrl: 'https://this-domain-does-not-exist.invalid'),
    );
    failingDio.interceptors.add(const CorextraDevToolsInterceptor());
    try {
      await failingDio.get('/x');
    } on DioException {
      // Expected — shows up red with no status code, just an error type.
    } finally {
      failingDio.close();
    }
  }

  void _validateForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    _notify(isValid ? 'Form is valid ✓' : 'Form has errors — see the fields above');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('corextra Demo')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _DevToolsSection(
                onLogInfo: () {
                  debugLog('Info log from the demo app');
                  _notify('Logged — check the DevTools Logs tab');
                },
                onLogWarning: () {
                  debugLog(
                    'Warning log from the demo app',
                    level: LogLevel.warning,
                  );
                  _notify('Logged — check the DevTools Logs tab');
                },
                onLogError: () {
                  AppLogger.logError('Something went wrong (demo)');
                  _notify('Logged — check the DevTools Logs tab');
                },
                onGet200: _sendGet200,
                onPostWithBody: _sendPostWithBody,
                onGet400: _sendGet400,
                onGet500: _sendGet500,
                onNetworkError: _sendNetworkError,
              ),
              const SizedBox(height: 16),
              _ResponsiveSection(constraints: constraints),
              const SizedBox(height: 16),
              _StateAndAnimationSection(
                message: stateMessage,
                showAnimatedText: showAnimatedText,
                onUpdateState: () {
                  safeSetState(() {
                    stateMessage = 'State updated safely at '
                        '${TimeOfDay.now().format(context)}';
                  });
                },
                onToggleAnimation: () =>
                    setState(() => showAnimatedText = !showAnimatedText),
              ),
              const SizedBox(height: 16),
              _FormValidatorsSection(
                formKey: _formKey,
                emailController: emailController,
                passwordController: passwordController,
                confirmController: confirmController,
                onValidate: _validateForm,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A titled, icon-labeled card used to group one feature area of the
/// demo. Keeps every section visually consistent.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.description,
  });

  final String title;
  final IconData icon;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 6),
              Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DevToolsSection extends StatelessWidget {
  const _DevToolsSection({
    required this.onLogInfo,
    required this.onLogWarning,
    required this.onLogError,
    required this.onGet200,
    required this.onPostWithBody,
    required this.onGet400,
    required this.onGet500,
    required this.onNetworkError,
  });

  final VoidCallback onLogInfo;
  final VoidCallback onLogWarning;
  final VoidCallback onLogError;
  final VoidCallback onGet200;
  final VoidCallback onPostWithBody;
  final VoidCallback onGet400;
  final VoidCallback onGet500;
  final VoidCallback onNetworkError;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'DevTools panel',
      icon: Icons.bug_report,
      description: 'Tap the floating bubble to open the panel, then press '
          'the buttons below and watch the Logs / Network / Performance '
          'tabs update live. Tip: tap Minimize to shrink the panel into a '
          'floating window, then press and hold its bottom-right corner '
          'before dragging to resize it.',
      children: [
        Text(
          'Logs',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: onLogInfo,
              child: const Text('Log info'),
            ),
            OutlinedButton(
              onPressed: onLogWarning,
              child: const Text('Log warning'),
            ),
            OutlinedButton(
              onPressed: onLogError,
              child: const Text('Log error'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Network — every case the panel can show',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: onGet200,
              child: const Text('GET 200'),
            ),
            FilledButton(
              onPressed: onPostWithBody,
              child: const Text('POST (body)'),
            ),
            FilledButton.tonal(
              onPressed: onGet400,
              child: const Text('GET 400'),
            ),
            FilledButton.tonal(
              onPressed: onGet500,
              child: const Text('GET 500'),
            ),
            FilledButton.tonal(
              onPressed: onNetworkError,
              child: const Text('Network error'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResponsiveSection extends StatelessWidget {
  const _ResponsiveSection({required this.constraints});

  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    String screenSizeLabel;
    if (ResponsiveBreakpoints.isXxl(constraints)) {
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

    final whenLabel = ResponsiveBreakpoints.when(
      constraints,
      base: () => 'Base Screen',
      smBuilder: () => '≥ SM Screen',
      mdBuilder: () => '≥ MD Screen',
      lgBuilder: () => '≥ LG Screen',
      xlBuilder: () => '≥ XL Screen',
      xxlBuilder: () => '≥ 2XL Screen',
    );

    return _SectionCard(
      title: 'Responsive helpers',
      icon: Icons.aspect_ratio,
      children: [
        Text('Via breakpoint helpers: $screenSizeLabel'),
        const SizedBox(height: 4),
        Text('Via ResponsiveBreakpoints.when: $whenLabel'),
      ],
    );
  }
}

class _StateAndAnimationSection extends StatelessWidget {
  const _StateAndAnimationSection({
    required this.message,
    required this.showAnimatedText,
    required this.onUpdateState,
    required this.onToggleAnimation,
  });

  final String message;
  final bool showAnimatedText;
  final VoidCallback onUpdateState;
  final VoidCallback onToggleAnimation;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'State & animation',
      icon: Icons.auto_awesome_motion,
      children: [
        Row(
          children: [
            OutlinedButton(
              onPressed: onUpdateState,
              child: const Text('Update state safely'),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onToggleAnimation,
          child: const Text('Toggle FadeSlideTransition'),
        ),
        const SizedBox(height: 12),
        FadeSlideTransition(
          direction: SlideDirection.bottom,
          duration: const Duration(milliseconds: 400),
          child: showAnimatedText
              ? const Text(
                  'Hello from FadeSlideTransition',
                  key: ValueKey('visible'),
                )
              : const SizedBox.shrink(key: ValueKey('hidden')),
        ),
      ],
    );
  }
}

class _FormValidatorsSection extends StatelessWidget {
  const _FormValidatorsSection({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.onValidate,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Form validators',
      icon: Icons.fact_check_outlined,
      children: [
        Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: FormValidators.email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (val) =>
                    FormValidators.password(val, minLength: 6),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (val) => FormValidators.confirmPassword(
                  val,
                  passwordController.text,
                  minLength: 6,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'OTP',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => FormValidators.otp(val, length: 4),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Required field',
                  border: OutlineInputBorder(),
                ),
                validator: FormValidators.required,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: onValidate,
                  child: const Text('Validate'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
