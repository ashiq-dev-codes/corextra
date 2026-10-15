import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'devtools_find.dart';

const findMatchColor = Color(0xFFFFE066);
const findMatchTextColor = Color(0xFF1A1A1A);
const _currentColor = Color(0xFFFF9632);

/// A drop-in for [Text] / [SelectableText] with browser-style find highlights; give it the [id] its [FindSource] uses so it can show and scroll to the current match.
class FindText extends StatefulWidget {
  const FindText(
    String this.data, {
    super.key,
    this.id,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.selectable = false,
  }) : span = null;

  const FindText.rich(
    TextSpan this.span, {
    super.key,
    this.id,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.selectable = false,
  }) : data = null;

  final String? data;
  final TextSpan? span;
  final String? id;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  /// Renders as [SelectableText] instead of [Text].
  final bool selectable;

  @override
  State<FindText> createState() => _FindTextState();
}

class _FindTextState extends State<FindText> {
  TextSelection? _currentRange;
  bool _revealScheduled = false;

  @override
  Widget build(BuildContext context) {
    final find = DevToolsFind.maybeOf(context);
    final needle = find?.needle ?? '';
    final source = widget.span ?? TextSpan(text: widget.data);
    final starts =
        needle.isEmpty
            ? const <int>[]
            : findMatches(source.toPlainText(), needle);
    _currentRange = null;
    if (starts.isEmpty) return _render(null);

    final hit = find!.current;
    final occurrence =
        widget.id != null && hit?.target.id == widget.id
            ? hit!.occurrence
            : null;
    final currentStart =
        occurrence == null ? null : starts.elementAtOrNull(occurrence);
    if (currentStart != null) {
      _currentRange = TextSelection(
        baseOffset: currentStart,
        extentOffset: currentStart + needle.length,
      );
      if (find.revealPending) _scheduleReveal(find);
    }
    return _render(
      _HighlightBuilder(
        starts: starts,
        length: needle.length,
        current: currentStart,
      ).build(source),
    );
  }

  /// With nothing to highlight, renders exactly the widget it stands in for.
  Widget _render(TextSpan? highlighted) {
    final span = highlighted ?? widget.span;
    if (widget.selectable) {
      return span == null
          ? SelectableText(
            widget.data!,
            style: widget.style,
            maxLines: widget.maxLines,
            textAlign: widget.textAlign,
          )
          : SelectableText.rich(
            span,
            style: widget.style,
            maxLines: widget.maxLines,
            textAlign: widget.textAlign,
          );
    }
    return span == null
        ? Text(
          widget.data!,
          style: widget.style,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
          textAlign: widget.textAlign,
        )
        : Text.rich(
          span,
          style: widget.style,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
          textAlign: widget.textAlign,
        );
  }

  void _scheduleReveal(DevToolsFind find) {
    if (_revealScheduled) return;
    _revealScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _revealScheduled = false;
      final range = _currentRange;
      if (!mounted || range == null || !find.revealPending) return;
      find.markRevealed();
      _showOnScreen(range);
    });
  }

  /// showOnScreen walks every scrollable above — list, code block, both axes — so the exact words land in view, not just this widget's top.
  void _showOnScreen(TextSelection range) {
    final text = _findTextRenderObject(context.findRenderObject());
    if (text == null) return;
    final boxes = switch (text) {
      RenderParagraph() => text.getBoxesForSelection(range),
      RenderEditable() => text.getBoxesForSelection(range),
      _ => const <TextBox>[],
    };
    final rect =
        boxes.isEmpty
            ? null
            : boxes
                .map((box) => box.toRect())
                .reduce((a, b) => a.expandToInclude(b))
                .inflate(32);
    text.showOnScreen(
      rect: rect,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  static RenderBox? _findTextRenderObject(RenderObject? root) {
    if (root == null) return null;
    if (root is RenderParagraph || root is RenderEditable) {
      return root as RenderBox;
    }
    RenderBox? found;
    root.visitChildren((child) => found ??= _findTextRenderObject(child));
    return found;
  }
}

/// Splits each piece of styled text at match boundaries, since a match can straddle pieces — e.g. a JSON key and its value.
class _HighlightBuilder {
  _HighlightBuilder({
    required this.starts,
    required this.length,
    required this.current,
  });

  final List<int> starts;
  final int length;
  final int? current;

  int _offset = 0;

  static const _matchStyle = TextStyle(
    backgroundColor: findMatchColor,
    color: findMatchTextColor,
  );
  static const _currentStyle = TextStyle(
    backgroundColor: _currentColor,
    color: findMatchTextColor,
    fontWeight: FontWeight.bold,
  );

  TextSpan build(TextSpan root) => _visit(root) as TextSpan;

  InlineSpan _visit(InlineSpan span) {
    if (span is! TextSpan) {
      // toPlainText counts a placeholder as one character.
      _offset += 1;
      return span;
    }
    final pieces = span.text == null ? null : _split(span.text!);
    final children = span.children?.map(_visit).toList();
    return TextSpan(
      style: span.style,
      recognizer: span.recognizer,
      semanticsLabel: span.semanticsLabel,
      children: [...?pieces, ...?children],
    );
  }

  List<InlineSpan> _split(String text) {
    final base = _offset;
    _offset += text.length;
    final out = <InlineSpan>[];
    var cursor = 0;
    for (final start in starts) {
      final from = (start - base).clamp(0, text.length);
      final to = (start + length - base).clamp(0, text.length);
      if (from >= to) continue;
      if (from > cursor) out.add(TextSpan(text: text.substring(cursor, from)));
      out.add(
        TextSpan(
          text: text.substring(from, to),
          style: start == current ? _currentStyle : _matchStyle,
        ),
      );
      cursor = to;
    }
    if (cursor < text.length) out.add(TextSpan(text: text.substring(cursor)));
    return out;
  }
}
