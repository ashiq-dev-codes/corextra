import 'package:flutter/material.dart';

import '../../find/find.dart';

/// A centered icon, message and optional hint shown when a DevTools tab has nothing to show yet.
///
/// Use it in a custom tab so its empty screen looks like the built-in ones.
///
/// Example:
/// ```dart
/// if (events.isEmpty) {
///   return const DevToolsEmptyState(
///     icon: LucideIcons.wifiOff,
///     message: 'No socket messages yet',
///     hint: 'Connect a socket to see messages here.',
///   );
/// }
/// ```
class DevToolsEmptyState extends StatelessWidget {
  /// Creates an empty state with an [icon], a [message] and an optional [hint].
  const DevToolsEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.hint,
    this.findId,
  });

  // ---------------- Content ----------------

  /// The large muted icon above the message.
  final IconData icon;

  /// The main line, saying what's missing.
  final String message;

  /// A smaller line under [message], usually telling the user how to get data; hidden when null.
  final String? hint;

  /// Prefix of the ids the owning tab's find source lists this text under, if it does.
  final String? findId;

  // ---------------- Build ----------------

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
