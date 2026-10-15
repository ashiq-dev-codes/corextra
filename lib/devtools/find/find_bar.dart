import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'devtools_find.dart';

/// The one search box for the whole panel: Enter / Shift+Enter or the arrows step through matches, Esc clears.
class DevToolsFindBar extends StatefulWidget {
  const DevToolsFindBar({super.key, required this.find, this.focusNode});

  final DevToolsFind find;
  final FocusNode? focusNode;

  @override
  State<DevToolsFindBar> createState() => _DevToolsFindBarState();
}

class _DevToolsFindBarState extends State<DevToolsFindBar> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _clear() {
    _text.clear();
    widget.find.search('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: SizedBox(
        height: 38,
        child: CallbackShortcuts(
          // A hardware Enter steps and keeps focus, so repeated Enter keeps stepping like a browser.
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter): widget.find.next,
            const SingleActivator(LogicalKeyboardKey.numpadEnter):
                widget.find.next,
            const SingleActivator(LogicalKeyboardKey.enter, shift: true):
                widget.find.previous,
            const SingleActivator(LogicalKeyboardKey.escape): _clear,
          },
          child: TextField(
            controller: _text,
            focusNode: widget.focusNode,
            onChanged: widget.find.search,
            // Only the on-screen keyboard's search key gets here; it steps, then the default closes the keyboard so the match is visible.
            onSubmitted: (_) => widget.find.next(),
            // Mobile keeps the keyboard up on outside taps by default; a tap or scroll anywhere else should put it away.
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Find in DevTools',
              prefixIcon: const Icon(LucideIcons.search, size: 16),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              suffixIcon: ListenableBuilder(
                listenable: Listenable.merge([_text, widget.find]),
                builder: (context, _) {
                  if (_text.text.isEmpty) return const SizedBox.shrink();
                  return _FindControls(find: widget.find, onClear: _clear);
                },
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FindControls extends StatelessWidget {
  const _FindControls({required this.find, required this.onClear});

  final DevToolsFind find;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = find.hits.length;
    final hasHits = count > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (find.isActive)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Text(
              hasHits ? '${find.position}/$count' : 'No results',
              key: const Key('devtools-find-counter'),
              style: TextStyle(
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
                color:
                    hasHits
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.error,
              ),
            ),
          ),
        _CompactIconButton(
          tooltip: 'Previous match',
          icon: LucideIcons.chevronUp,
          onPressed: hasHits ? find.previous : null,
        ),
        _CompactIconButton(
          tooltip: 'Next match',
          icon: LucideIcons.chevronDown,
          onPressed: hasHits ? find.next : null,
        ),
        _CompactIconButton(
          tooltip: 'Clear',
          icon: LucideIcons.x,
          onPressed: onClear,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _CompactIconButton extends StatelessWidget {
  const _CompactIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      iconSize: 16,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }
}
