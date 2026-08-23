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
      builder: (context, child) => CorextraDevToolsOverlay(
        // Force the bubble on in release builds for the demo video.
        enabled: true,
        child: child ?? const SizedBox.shrink(),
      ),
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
    dio = Dio(BaseOptions(baseUrl: 'https://httpbin.org'));
    dio.interceptors.add(const AppLoggerInterceptor());
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
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  Future<void> _sendGet200() async {
    _notify('GET 200 sent — check the Network tab');
    try {
      await dio.get('/get');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> _sendGetWithQueryParams() async {
    _notify('GET (query params) sent — check the Payload tab');
    try {
      await dio.get(
        '/get',
        queryParameters: {'demo': 'corextra', 'page': '2', 'sort': 'desc'},
      );
    } on DioException {
      /* ignore */
    }
  }

  Future<void> _sendPostWithBody() async {
    _notify('POST sent — check the request/response body in the Network tab');
    try {
      await dio.post(
        '/post',
        data: {'name': 'corextra', 'feature': 'DevTools'},
        options: Options(headers: {'Authorization': 'Bearer secret-token'}),
      );
    } on DioException {
      /* ignore */
    }
  }

  Future<void> _sendPutWithBody() async {
    _notify('PUT sent — check the Payload tab in the Network tab');
    try {
      await dio.put('/put', data: {'name': 'corextra', 'version': '2.0.0'});
    } on DioException {
      /* ignore */
    }
  }

  Future<void> _sendPatchWithRawBody() async {
    _notify('PATCH (raw body) sent — check the Payload tab');
    try {
      await dio.patch(
        '/patch',
        data: 'raw text payload, not JSON — line one\nline two',
        options: Options(contentType: Headers.textPlainContentType),
      );
    } on DioException {
      /* ignore */
    }
  }

  Future<void> _sendDelete() async {
    _notify('DELETE sent — check the Network tab');
    try {
      await dio.delete('/delete');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> _sendMultipartFormData() async {
    _notify('Multipart form sent — check the Payload tab');
    try {
      final form = FormData.fromMap({'name': 'corextra', 'version': '2.0.0'});
      form.files.add(
        MapEntry(
          'avatar',
          MultipartFile.fromBytes(
            List.generate(64, (i) => i % 256),
            filename: 'avatar.png',
            contentType: DioMediaType('image', 'png'),
          ),
        ),
      );
      await dio.post('/post', data: form);
    } on DioException {
      /* ignore */
    }
  }

  Future<void> _sendBinaryResponse() async {
    _notify('Binary response sent — check the Response tab');
    try {
      await dio.get(
        '/image/png',
        options: Options(responseType: ResponseType.bytes),
      );
    } on DioException {
      /* ignore */
    }
  }

  Future<void> _sendHtmlResponse() async {
    _notify('HTML response sent — check the Response tab');
    try {
      await dio.get('/html');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> _sendLargeResponse() async {
    _notify('Large response sent — check the Payload tab in the Network tab');
    try {
      await dio.post(
        '/anything',
        data: {
          'items': List.generate(
            400,
            (i) =>
                'Item #$i — lorem ipsum dolor sit amet, consectetur adipiscing elit.',
          ),
        },
      );
    } on DioException {
      /* ignore */
    }
  }

  Future<void> _sendGet400() async {
    _notify('GET 400 sent — check the Network tab');
    try {
      await dio.get('/status/400');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> _sendUnauthorized() async {
    _notify('GET 401 (Unauthorized) sent');
    try {
      await dio.get('/status/401');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> _sendForbidden() async {
    _notify('GET 403 (Forbidden) sent');
    try {
      await dio.get('/status/403');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> _sendGet500() async {
    _notify('GET 500 sent — check the Network tab');
    try {
      await dio.get('/status/500');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> _sendTimeout() async {
    _notify('Sending request with short timeout — check the Network tab');
    try {
      await dio.get(
        '/delay/5',
        options: Options(receiveTimeout: const Duration(seconds: 1)),
      );
    } on DioException {
      /* ignore */
    }
  }

  Future<void> _sendRedirect() async {
    _notify('GET 302 (Redirect) sent');
    try {
      await dio.get('/redirect/1');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> _sendParallelRequests() async {
    _notify('Sending 3 parallel requests');
    try {
      await Future.wait([dio.get('/get'), dio.get('/get'), dio.get('/get')]);
    } on DioException {
      /* ignore */
    }
  }

  Future<void> _sendNetworkError() async {
    _notify(
      'Sending a request that will fail to connect — check the Network tab',
    );
    final failingDio = Dio(
      BaseOptions(baseUrl: 'https://this-domain-does-not-exist.invalid'),
    );
    failingDio.interceptors.add(const CorextraDevToolsInterceptor());
    try {
      await failingDio.get('/x');
    } on DioException {
      /* ignore */
    } finally {
      failingDio.close();
    }
  }

  void _validateForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    _notify(
      isValid ? 'Form is valid ✓' : 'Form has errors — see the fields above',
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('corextra Demo'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.apps), text: 'Features'),
              Tab(icon: Icon(Icons.bug_report), text: 'DevTools'),
            ],
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return TabBarView(
              children: [
                _NonDevToolsTab(
                  constraints: constraints,
                  formKey: _formKey,
                  emailController: emailController,
                  passwordController: passwordController,
                  confirmController: confirmController,
                  onValidate: _validateForm,
                ),
                _DevToolsTab(
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
                  onGetWithQueryParams: _sendGetWithQueryParams,
                  onPostWithBody: _sendPostWithBody,
                  onPutWithBody: _sendPutWithBody,
                  onPatchWithRawBody: _sendPatchWithRawBody,
                  onDelete: _sendDelete,
                  onMultipartFormData: _sendMultipartFormData,
                  onBinaryResponse: _sendBinaryResponse,
                  onHtmlResponse: _sendHtmlResponse,
                  onLargeResponse: _sendLargeResponse,
                  onGet400: _sendGet400,
                  onUnauthorized: _sendUnauthorized,
                  onForbidden: _sendForbidden,
                  onGet500: _sendGet500,
                  onTimeout: _sendTimeout,
                  onRedirect: _sendRedirect,
                  onParallelRequests: _sendParallelRequests,
                  onNetworkError: _sendNetworkError,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NonDevToolsTab extends StatefulWidget {
  const _NonDevToolsTab({
    required this.constraints,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.onValidate,
  });

  final BoxConstraints constraints;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final VoidCallback onValidate;

  @override
  State<_NonDevToolsTab> createState() => _NonDevToolsTabState();
}

class _NonDevToolsTabState extends State<_NonDevToolsTab> {
  String stateMessage = 'Initial state';
  bool showAnimatedText = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ResponsiveSection(constraints: widget.constraints),
        const SizedBox(height: 16),
        _StateAndAnimationSection(
          message: stateMessage,
          showAnimatedText: showAnimatedText,
          onUpdateState: () {
            setState(() {
              stateMessage =
                  'State updated at ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}';
            });
          },
          onToggleAnimation: () {
            setState(() {
              showAnimatedText = !showAnimatedText;
            });
          },
        ),
        const SizedBox(height: 16),
        _FormValidatorsSection(
          formKey: widget.formKey,
          emailController: widget.emailController,
          passwordController: widget.passwordController,
          confirmController: widget.confirmController,
          onValidate: widget.onValidate,
        ),
      ],
    );
  }
}

class _DevToolsTab extends StatelessWidget {
  const _DevToolsTab({
    required this.onLogInfo,
    required this.onLogWarning,
    required this.onLogError,
    required this.onGet200,
    required this.onGetWithQueryParams,
    required this.onPostWithBody,
    required this.onPutWithBody,
    required this.onPatchWithRawBody,
    required this.onDelete,
    required this.onMultipartFormData,
    required this.onBinaryResponse,
    required this.onHtmlResponse,
    required this.onLargeResponse,
    required this.onGet400,
    required this.onUnauthorized,
    required this.onForbidden,
    required this.onGet500,
    required this.onTimeout,
    required this.onRedirect,
    required this.onParallelRequests,
    required this.onNetworkError,
  });

  final VoidCallback onLogInfo;
  final VoidCallback onLogWarning;
  final VoidCallback onLogError;
  final VoidCallback onGet200;
  final VoidCallback onGetWithQueryParams;
  final VoidCallback onPostWithBody;
  final VoidCallback onPutWithBody;
  final VoidCallback onPatchWithRawBody;
  final VoidCallback onDelete;
  final VoidCallback onMultipartFormData;
  final VoidCallback onBinaryResponse;
  final VoidCallback onHtmlResponse;
  final VoidCallback onLargeResponse;
  final VoidCallback onGet400;
  final VoidCallback onUnauthorized;
  final VoidCallback onForbidden;
  final VoidCallback onGet500;
  final VoidCallback onTimeout;
  final VoidCallback onRedirect;
  final VoidCallback onParallelRequests;
  final VoidCallback onNetworkError;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DevToolsSection(
          onLogInfo: onLogInfo,
          onLogWarning: onLogWarning,
          onLogError: onLogError,
          onGet200: onGet200,
          onGetWithQueryParams: onGetWithQueryParams,
          onPostWithBody: onPostWithBody,
          onPutWithBody: onPutWithBody,
          onPatchWithRawBody: onPatchWithRawBody,
          onDelete: onDelete,
          onMultipartFormData: onMultipartFormData,
          onBinaryResponse: onBinaryResponse,
          onHtmlResponse: onHtmlResponse,
          onLargeResponse: onLargeResponse,
          onGet400: onGet400,
          onUnauthorized: onUnauthorized,
          onForbidden: onForbidden,
          onGet500: onGet500,
          onTimeout: onTimeout,
          onRedirect: onRedirect,
          onParallelRequests: onParallelRequests,
          onNetworkError: onNetworkError,
        ),
      ],
    );
  }
}

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
    required this.onGetWithQueryParams,
    required this.onPostWithBody,
    required this.onPutWithBody,
    required this.onPatchWithRawBody,
    required this.onDelete,
    required this.onMultipartFormData,
    required this.onBinaryResponse,
    required this.onHtmlResponse,
    required this.onLargeResponse,
    required this.onGet400,
    required this.onUnauthorized,
    required this.onForbidden,
    required this.onGet500,
    required this.onTimeout,
    required this.onRedirect,
    required this.onParallelRequests,
    required this.onNetworkError,
  });

  final VoidCallback onLogInfo;
  final VoidCallback onLogWarning;
  final VoidCallback onLogError;
  final VoidCallback onGet200;
  final VoidCallback onGetWithQueryParams;
  final VoidCallback onPostWithBody;
  final VoidCallback onPutWithBody;
  final VoidCallback onPatchWithRawBody;
  final VoidCallback onDelete;
  final VoidCallback onMultipartFormData;
  final VoidCallback onBinaryResponse;
  final VoidCallback onHtmlResponse;
  final VoidCallback onLargeResponse;
  final VoidCallback onGet400;
  final VoidCallback onUnauthorized;
  final VoidCallback onForbidden;
  final VoidCallback onGet500;
  final VoidCallback onTimeout;
  final VoidCallback onRedirect;
  final VoidCallback onParallelRequests;
  final VoidCallback onNetworkError;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'DevTools panel',
      icon: Icons.bug_report,
      description:
          'Tap the floating bubble to open the panel, then press '
          'the buttons below and watch the Logs / Network / Performance '
          'tabs update live. Tips: tap Minimize to shrink the panel into a '
          'floating window, then press and hold its bottom-right corner '
          'before dragging to resize it. Tap a Network row (try "Large '
          'response") to see its Headers / Payload / Response tabs — '
          'each scrolls on its own. Its Payload tab is big enough to '
          'get truncated, and still stays properly indented JSON even '
          'once cut off.',
      children: [
        Text('Logs', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(onPressed: onLogInfo, child: const Text('Log info')),
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
            FilledButton(onPressed: onGet200, child: const Text('GET 200')),
            FilledButton(
              onPressed: onGetWithQueryParams,
              child: const Text('GET (query params)'),
            ),
            FilledButton(
              onPressed: onPostWithBody,
              child: const Text('POST (body)'),
            ),
            FilledButton(
              onPressed: onPutWithBody,
              child: const Text('PUT (body)'),
            ),
            FilledButton(
              onPressed: onPatchWithRawBody,
              child: const Text('PATCH (raw body)'),
            ),
            FilledButton(onPressed: onDelete, child: const Text('DELETE')),
            FilledButton(
              onPressed: onMultipartFormData,
              child: const Text('Multipart (FormData)'),
            ),
            FilledButton(
              onPressed: onBinaryResponse,
              child: const Text('Binary response'),
            ),
            FilledButton(
              onPressed: onHtmlResponse,
              child: const Text('HTML response'),
            ),
            FilledButton(
              onPressed: onLargeResponse,
              child: const Text('Large response'),
            ),
            FilledButton.tonal(
              onPressed: onGet400,
              child: const Text('GET 400'),
            ),
            FilledButton.tonal(
              onPressed: onUnauthorized,
              child: const Text('GET 401'),
            ),
            FilledButton.tonal(
              onPressed: onForbidden,
              child: const Text('GET 403'),
            ),
            FilledButton.tonal(
              onPressed: onGet500,
              child: const Text('GET 500'),
            ),
            FilledButton.tonal(
              onPressed: onTimeout,
              child: const Text('Timeout'),
            ),
            FilledButton.tonal(
              onPressed: onRedirect,
              child: const Text('Redirect'),
            ),
            FilledButton.tonal(
              onPressed: onParallelRequests,
              child: const Text('Parallel (3)'),
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
                validator: (val) => FormValidators.password(val, minLength: 6),
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
