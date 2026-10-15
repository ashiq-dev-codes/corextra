import 'package:flutter/material.dart';

import '../find/find_text.dart';

/// A centered icon + message shown when a DevTools tab has no data yet.
class DevToolsEmptyState extends StatelessWidget {
  const DevToolsEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.hint,
    this.findId,
  });

  final IconData icon;
  final String message;
  final String? hint;

  /// Prefix of the ids the owning tab's find source lists this text under, if it does.
  final String? findId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    return Center(
      // Scrolls rather than overflows in the floating window at its smallest.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: mutedColor),
            const SizedBox(height: 12),
            FindText(
              message,
              id: findId == null ? null : '$findId/message',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: mutedColor),
            ),
            if (hint != null) ...[
              const SizedBox(height: 6),
              FindText(
                hint!,
                id: findId == null ? null : '$findId/hint',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
