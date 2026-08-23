import 'package:flutter/material.dart';
import 'package:corextra/corextra.dart';
import '../../application/demo_controller.dart';
import '../widgets/section_card.dart';

class FeaturesTab extends StatelessWidget {
  final BoxConstraints constraints;
  final DemoController controller;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final VoidCallback onValidate;

  const FeaturesTab({
    super.key,
    required this.constraints,
    required this.controller,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildResponsiveSection(),
        _buildStateAndAnimationSection(),
        _buildFormValidatorsSection(),
      ],
    );
  }

  Widget _buildResponsiveSection() {
    final breakpointName = _getBreakpointName();
    return SectionCard(
      title: 'Responsive Helpers',
      child: Column(
        children: [
          Text('Screen width: ${constraints.maxWidth.toStringAsFixed(0)}'),
          Text('Breakpoint: $breakpointName'),
        ],
      ),
    );
  }

  String _getBreakpointName() {
    if (ResponsiveBreakpoints.isXxl(constraints)) return '2XL';
    if (ResponsiveBreakpoints.isXl(constraints)) return 'XL';
    if (ResponsiveBreakpoints.isLg(constraints)) return 'LG';
    if (ResponsiveBreakpoints.isMd(constraints)) return 'MD';
    return 'SM';
  }

  Widget _buildStateAndAnimationSection() {
    return SectionCard(
      title: 'State & Animation Helpers',
      child: Column(
        children: [
          Text(controller.stateMessage),
          ElevatedButton(
            onPressed: controller.updateState,
            child: const Text('Update State'),
          ),
          const SizedBox(height: 10),
          if (controller.showAnimatedText)
            FadeSlideTransition(
              direction: SlideDirection.bottom,
              duration: const Duration(milliseconds: 300),
              child: const Text('Hello from Corextra!'),
            ),
          ElevatedButton(
            onPressed: controller.toggleAnimation,
            child: Text(controller.showAnimatedText ? 'Hide' : 'Show'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormValidatorsSection() {
    return SectionCard(
      title: 'Form Validators',
      child: Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: FormValidators.email,
            ),
            TextFormField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (value) => FormValidators.password(value),
            ),
            TextFormField(
              controller: confirmController,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
              validator: (value) => FormValidators.confirmPassword(
                value,
                passwordController.text,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: onValidate,
              child: const Text('Validate'),
            ),
          ],
        ),
      ),
    );
  }
}