import 'package:flutter/material.dart';

import '../../application/demo_controller.dart';
import '../../infrastructure/network/network_service.dart';
import '../tabs/devtools_tab.dart';
import '../tabs/features_tab.dart';

/// Demo tabbed scaffold managing DemoController and form state.
class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  late final DemoController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DemoController(networkService: NetworkService());
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  void _validateForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    _notify(
      isValid ? 'Form is valid ✓' : 'Form has errors — see the fields above',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('corextra'),
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.primaryContainer,
            ),
            indicatorPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            dividerColor: Colors.transparent,
            labelColor: colorScheme.onPrimaryContainer,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            splashBorderRadius: BorderRadius.circular(12),
            tabs: const [
              Tab(icon: Icon(Icons.apps_rounded), text: 'Features'),
              Tab(icon: Icon(Icons.bug_report_rounded), text: 'DevTools'),
            ],
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return TabBarView(
              children: [
                FeaturesTab(
                  constraints: constraints,
                  controller: _controller,
                  formKey: _formKey,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  confirmController: _confirmController,
                  onValidate: _validateForm,
                ),
                DevToolsTab(controller: _controller, onNotify: _notify),
              ],
            );
          },
        ),
      ),
    );
  }
}
