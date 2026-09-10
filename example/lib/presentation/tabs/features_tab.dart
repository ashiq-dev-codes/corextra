import 'package:corextra/corextra.dart';
import 'package:flutter/material.dart';

import '../../application/demo_controller.dart';
import '../widgets/section_card.dart';

class FeaturesTab extends StatelessWidget {
  final BoxConstraints constraints;
  final DemoController controller;
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final TextEditingController websiteController;
  final VoidCallback onValidate;

  const FeaturesTab({
    super.key,
    required this.constraints,
    required this.controller,
    required this.formKey,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.websiteController,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        _buildResponsiveSection(context),
        _buildStateAndAnimationSection(context),
        _buildFormValidatorsSection(context),
      ],
    );
  }

  Widget _buildResponsiveSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final breakpointName = _getBreakpointName();
    // Picks a value per breakpoint directly, no LayoutBuilder builder-callbacks needed.
    final columns = constraints.responsive<int>(base: 1, md: 2, lg: 3, xl: 4);
    return SectionCard(
      title: 'Responsive Helpers',
      icon: Icons.aspect_ratio_rounded,
      subtitle: 'Breakpoint, device type and value helpers react to the live screen width.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _StatChip(
            label: 'Width',
            value: '${constraints.maxWidth.toStringAsFixed(0)}px',
            color: colorScheme.primaryContainer,
            onColor: colorScheme.onPrimaryContainer,
          ),
          _StatChip(
            label: 'Breakpoint',
            value: breakpointName,
            color: colorScheme.tertiaryContainer,
            onColor: colorScheme.onTertiaryContainer,
          ),
          _StatChip(
            label: 'Device Type',
            value: constraints.deviceType.name.capitalize(),
            color: colorScheme.secondaryContainer,
            onColor: colorScheme.onSecondaryContainer,
          ),
          _StatChip(
            label: 'Columns (responsive<int>)',
            value: '$columns',
            color: colorScheme.primaryContainer,
            onColor: colorScheme.onPrimaryContainer,
          ),
          _StatChip(
            label: 'Orientation',
            value: context.isPortrait ? 'Portrait' : 'Landscape',
            color: colorScheme.tertiaryContainer,
            onColor: colorScheme.onTertiaryContainer,
          ),
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

  Widget _buildStateAndAnimationSection(BuildContext context) {
    return SectionCard(
      title: 'State & Animation',
      icon: Icons.auto_awesome_motion_rounded,
      subtitle: 'Trigger a state update, then fade-slide a widget in.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              controller.stateMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: controller.updateState,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Update State'),
              ),
              OutlinedButton.icon(
                onPressed: controller.toggleAnimation,
                icon: Icon(
                  controller.showAnimatedText
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 18,
                ),
                label: Text(controller.showAnimatedText ? 'Hide' : 'Show'),
              ),
            ],
          ),
          if (controller.showAnimatedText) ...[
            const SizedBox(height: 12),
            FadeSlideTransition(
              direction: SlideDirection.bottom,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.celebration_rounded,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Hello from Corextra!',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormValidatorsSection(BuildContext context) {
    return SectionCard(
      title: 'Form Validators',
      icon: Icons.fact_check_rounded,
      subtitle: 'Built-in validators for common field patterns.',
      child: Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              // compose() chains validators and returns the first error found.
              validator: FormValidators.compose([
                FormValidators.required,
                (value) => FormValidators.minLength(
                  value,
                  3,
                  message: 'Username must be at least 3 characters',
                ),
              ]),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: FormValidators.compose([
                FormValidators.required,
                FormValidators.email,
              ]),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              validator: (value) => FormValidators.password(value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_reset_rounded),
              ),
              validator: (value) => FormValidators.confirmPassword(
                value,
                passwordController.text,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: websiteController,
              decoration: const InputDecoration(
                labelText: 'Website (optional)',
                prefixIcon: Icon(Icons.link_rounded),
              ),
              // optional() skips the wrapped validator when the field is left empty.
              validator: FormValidators.optional(FormValidators.url),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onValidate,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Validate'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color onColor;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: onColor.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w700, color: onColor),
          ),
        ],
      ),
    );
  }
}
