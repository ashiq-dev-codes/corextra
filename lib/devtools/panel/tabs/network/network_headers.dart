part of 'network_tab.dart';

// ---------------- Sensitive headers ----------------

/// Header names known to carry credentials; their rows get a TOKEN badge and Copy and Share buttons.
const _sensitiveHeaderNames = {
  'authorization',
  'proxy-authorization',
  'cookie',
  'set-cookie',
  'x-api-key',
  'api-key',
  'x-auth-token',
  'x-access-token',
  'access-token',
  'x-csrf-token',
  'x-xsrf-token',
  'x-session-token',
};

bool _isSensitiveHeader(String key) =>
    _sensitiveHeaderNames.contains(key.toLowerCase());

/// Masks a hidden value but keeps the last few characters so testers can tell tokens apart; short values are fully masked.
String _maskedPreview(String value) {
  const visibleTail = 4;
  const minMaskedChars = 3;
  if (value.length <= visibleTail + minMaskedChars) return '***';
  return '***${value.substring(value.length - visibleTail)}';
}

bool _isHiddenHeader(String key, Set<String> hiddenKeys) =>
    hiddenKeys.contains(key.toLowerCase());

/// What a header row shows; find searches this, never the real value of a masked header.
String _headerDisplayValue(
  MapEntry<String, String> entry,
  Set<String> hiddenKeys,
) =>
    _isHiddenHeader(entry.key, hiddenKeys)
        ? _maskedPreview(entry.value)
        : entry.value;

// ---------------- Header list ----------------

/// Headers as a readable key/value list instead of a raw `Map.toString()` dump.
class _KeyValueList extends StatelessWidget {
  const _KeyValueList({
    required this.data,
    required this.findPrefix,
    this.hiddenKeys = const {},
  });

  final Map<String, String> data;
  final Set<String> hiddenKeys;
  final String findPrefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) {
      return FindText(
        'No headers',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          data.entries.map((entry) {
            final hidden = _isHiddenHeader(entry.key, hiddenKeys);
            final sensitive = _isSensitiveHeader(entry.key) || hidden;
            final displayValue = _headerDisplayValue(entry, hiddenKeys);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        FindText(
                          entry.key,
                          id: '$findPrefix/k/${entry.key}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (sensitive) _TokenBadge(hidden: hidden),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FindText(
                      displayValue,
                      id: '$findPrefix/v/${entry.key}',
                      selectable: true,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontStyle: hidden ? FontStyle.italic : FontStyle.normal,
                        color:
                            hidden
                                ? theme.colorScheme.onSurfaceVariant
                                : sensitive
                                ? theme.colorScheme.primary
                                : null,
                      ),
                    ),
                  ),
                  if (sensitive) ...[
                    _CopyIconButton(text: () => entry.value),
                    _ShareIconButton(text: () => entry.value),
                  ],
                ],
              ),
            );
          }).toList(),
    );
  }
}

/// A small badge marking a header row flagged by [_isSensitiveHeader].
class _TokenBadge extends StatelessWidget {
  const _TokenBadge({required this.hidden});

  final bool hidden;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          hidden
              ? 'Masked on screen by hiddenHeaders — Copy still copies the real value'
              : 'Looks like an auth token or credential',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.keyRound, size: 9, color: Colors.amber),
            SizedBox(width: 2),
            Text(
              'TOKEN',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
