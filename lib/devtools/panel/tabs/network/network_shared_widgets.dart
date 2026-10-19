part of 'network_tab.dart';

// ---------------- Copy and Share ----------------

/// Copies [text] and shows a check for a second as feedback.
class _CopyIconButton extends StatefulWidget {
  const _CopyIconButton({required this.text});

  final ValueGetter<String> text;

  @override
  State<_CopyIconButton> createState() => _CopyIconButtonState();
}

class _CopyIconButtonState extends State<_CopyIconButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text()));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Copy',
      iconSize: 16,
      visualDensity: VisualDensity.compact,
      icon: Icon(_copied ? LucideIcons.check : LucideIcons.copy),
      onPressed: _copy,
    );
  }
}

/// Opens the share sheet for [text], anchored to this button so iPad's popover-style sheet doesn't crash.
class _ShareIconButton extends StatelessWidget {
  const _ShareIconButton({required this.text});

  final ValueGetter<String> text;

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    try {
      await shareText(text(), origin: origin);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Share',
      iconSize: 16,
      visualDensity: VisualDensity.compact,
      icon: const Icon(LucideIcons.share2),
      onPressed: () => _share(context),
    );
  }
}

// ---------------- Error banner ----------------

/// A small red banner for a request's error message.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.findId});

  final String message;
  final String findId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.circleAlert, size: 16, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: FindText(
              message,
              id: findId,
              style: const TextStyle(color: Colors.red, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
