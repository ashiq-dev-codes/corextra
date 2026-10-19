part of 'network_tab.dart';

// ---------------- Code line ----------------

/// One line of a body, from a JSON tree or plain text; the view and find both read these, so they always agree on the text.
class _CodeLine {
  const _CodeLine({
    required this.path,
    required this.depth,
    required this.keyPrefix,
    required this.text,
    this.trailing = '',
    this.value,
    this.muted = false,
    this.closeIndex,
    this.closeBrace = '',
    this.comma = '',
    this.countLabel = '',
  }) : plain = false;

  const _CodeLine.text(this.text)
    : path = '',
      depth = 0,
      keyPrefix = '',
      trailing = '',
      value = null,
      muted = false,
      plain = true,
      closeIndex = null,
      closeBrace = '',
      comma = '',
      countLabel = '';

  final String path;
  final int depth;
  final String keyPrefix;

  /// The literal, a brace, or for a plain line the whole line.
  final String text;
  final String trailing;

  /// The primitive this line shows, for coloring.
  final Object? value;

  /// A brace or an empty `{}`/`[]` rather than a value.
  final bool muted;

  /// A plain text line, not part of a JSON tree.
  final bool plain;

  /// Set on a foldable container's opening line: the index of its closing line.
  final int? closeIndex;
  final String closeBrace;
  final String comma;
  final String countLabel;

  bool get isOpen => closeIndex != null;

  String get plainText => '$keyPrefix$text$trailing';

  /// Pixels before the text starts: the tree indent, plus the fold chevron on a toggle line.
  double get indent => depth * 16.0 + (isOpen ? 30 : 0);

  /// What a folded toggle line appends (` … }, 3 keys`), so the block is wide enough either way.
  int get collapsedExtraChars =>
      isOpen ? 6 + closeBrace.length + comma.length + countLabel.length : 0;
}

// ---------------- JSON to lines ----------------

/// Turns decoded JSON into lines, linking each foldable opening line to its closing line.
List<_CodeLine> _flattenJson(Object value) {
  final lines = <_CodeLine?>[];

  void visit(
    Object? node,
    String path,
    String keyPrefix,
    String comma,
    int depth,
  ) {
    final children =
        node is Map
            ? [
              for (final entry in node.entries)
                (
                  keyPrefix: '"${entry.key}": ',
                  value: entry.value,
                  path: '$path.${entry.key}',
                ),
            ]
            : node is List
            ? [
              for (var i = 0; i < node.length; i++)
                (keyPrefix: '', value: node[i], path: '$path[$i]'),
            ]
            : null;
    if (children == null) {
      lines.add(
        _CodeLine(
          path: path,
          depth: depth,
          keyPrefix: keyPrefix,
          text: jsonEncode(node),
          trailing: comma,
          value: node,
        ),
      );
      return;
    }

    final (openBrace, closeBrace) = node is Map ? ('{', '}') : ('[', ']');
    if (children.isEmpty) {
      lines.add(
        _CodeLine(
          path: path,
          depth: depth,
          keyPrefix: keyPrefix,
          text: '$openBrace$closeBrace',
          trailing: comma,
          muted: true,
        ),
      );
      return;
    }

    // Reserved now, filled once the closing line's index is known.
    final openIndex = lines.length;
    lines.add(null);
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      visit(
        child.value,
        child.path,
        child.keyPrefix,
        i == children.length - 1 ? '' : ',',
        depth + 1,
      );
    }
    lines.add(
      _CodeLine(
        path: '$path/close',
        depth: depth,
        keyPrefix: '',
        text: closeBrace,
        trailing: comma,
        muted: true,
      ),
    );
    final noun = node is Map ? 'key' : 'item';
    lines[openIndex] = _CodeLine(
      path: path,
      depth: depth,
      keyPrefix: keyPrefix,
      text: openBrace,
      closeIndex: lines.length - 1,
      closeBrace: closeBrace,
      comma: comma,
      countLabel:
          children.length == 1 ? '1 $noun' : '${children.length} ${noun}s',
    );
  }

  visit(value, 'root', '', '', 0);
  return [for (final line in lines) line!];
}

// ---------------- Line widgets ----------------

/// Value colors from the panel's theme; light mode uses the `on*Container` roles because the plain accent colors look pale on a light surface.
Color _literalColor(Object? value, ThemeData theme) {
  final colors = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  if (value is String) {
    return isDark ? colors.tertiary : colors.onTertiaryContainer;
  }
  if (value is num) {
    return isDark ? colors.secondary : colors.onSecondaryContainer;
  }
  if (value is bool) {
    return isDark ? colors.primary : colors.onPrimaryContainer;
  }
  return colors.onSurfaceVariant;
}

/// A line that can't fold: plain text, a JSON value, an empty `{}` or `[]`, or a closing brace.
class _CodeLeafLine extends StatelessWidget {
  const _CodeLeafLine({
    required this.line,
    required this.findId,
    required this.theme,
  });

  final _CodeLine line;
  final String findId;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (line.plain) {
      return FindText(
        line.text,
        id: findId,
        selectable: true,
        style: _codeStyle,
      );
    }
    final valueColor =
        line.muted
            ? theme.colorScheme.onSurfaceVariant
            : _literalColor(line.value, theme);
    final italicValue = !line.muted && line.value == null;
    return Padding(
      padding: EdgeInsets.only(left: line.depth * 16.0),
      child: FindText.rich(
        TextSpan(
          style: _codeStyle,
          children: [
            if (line.keyPrefix.isNotEmpty)
              TextSpan(
                text: line.keyPrefix,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            TextSpan(
              text: line.text,
              style: TextStyle(
                color: valueColor,
                fontStyle: italicValue ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            TextSpan(
              text: line.trailing,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        id: findId,
        selectable: true,
      ),
    );
  }
}

/// The opening line of a foldable object or array; its chevron calls [onTap], and when folded it also shows the closing brace and item count.
class _CodeToggleLine extends StatelessWidget {
  const _CodeToggleLine({
    required this.line,
    required this.collapsed,
    required this.findId,
    required this.theme,
    required this.onTap,
  });

  final _CodeLine line;
  final bool collapsed;
  final String findId;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final punctStyle = _codeStyle.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: EdgeInsets.only(left: line.depth * 16.0, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 30,
                height: 30,
                child: Center(
                  child: Icon(
                    collapsed
                        ? LucideIcons.chevronRight
                        : LucideIcons.chevronDown,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          FindText.rich(
            TextSpan(
              style: punctStyle,
              children: [
                if (line.keyPrefix.isNotEmpty)
                  TextSpan(
                    text: line.keyPrefix,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                TextSpan(text: line.text),
                if (collapsed)
                  TextSpan(text: ' … ${line.closeBrace}${line.comma}'),
                if (collapsed)
                  TextSpan(
                    text: '  ${line.countLabel}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
              ],
            ),
            id: findId,
            selectable: true,
          ),
        ],
      ),
    );
  }
}
