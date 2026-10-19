import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'devtools_find.dart';
import 'find_aware.dart';
import 'models/find_hit.dart';

/// A lazily built list with separators that scrolls to the row holding the current match, even one it hasn't built yet.
class FindListView extends StatefulWidget {
  const FindListView({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorBuilder,
    required this.indexOfHit,
    this.itemKey,
    this.padding,
  });

  /// Scrolls the list.
  final ScrollController controller;

  /// How many rows there are.
  final int itemCount;

  /// Builds the row at an index.
  final IndexedWidgetBuilder itemBuilder;

  /// Builds the separator under the row at an index.
  final IndexedWidgetBuilder separatorBuilder;

  /// Space around the list.
  final EdgeInsetsGeometry? padding;

  /// A stable identity per row, so new data at the top moves existing rows instead of rebuilding them with other content.
  final Object Function(int index)? itemKey;

  /// The row [hit] lives in, or null when it isn't in this list.
  final int? Function(FindHit hit) indexOfHit;

  @override
  State<FindListView> createState() => _FindListViewState();
}

class _FindListViewState extends State<FindListView>
    with FindAware<FindListView> {
  @override
  void onFindReveal(FindHit hit) {
    final index = widget.indexOfHit(hit);
    final find = DevToolsFind.maybeOf(context, listen: false);
    if (index == null || index < 0 || find == null) return;
    revealListRow(
      find,
      widget.controller,
      index: index,
      count: widget.itemCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemKey = widget.itemKey;
    Map<Object, int>? indexByKey;
    // A builder with each separator under its row, not ListView.separated, whose key-lookup API differs across supported Flutter versions.
    return ListView.builder(
      controller: widget.controller,
      padding: widget.padding,
      itemCount: widget.itemCount,
      findChildIndexCallback:
          itemKey == null
              ? null
              : (key) {
                final lookup =
                    indexByKey ??= {
                      for (var i = 0; i < widget.itemCount; i++) itemKey(i): i,
                    };
                return key is ValueKey ? lookup[key.value] : null;
              },
      itemBuilder: (context, index) {
        final row = widget.itemBuilder(context, index);
        final child =
            index == widget.itemCount - 1
                ? row
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [row, widget.separatorBuilder(context, index)],
                );
        return itemKey == null
            ? child
            : KeyedSubtree(key: ValueKey(itemKey(index)), child: child);
      },
    );
  }
}

/// A lazy list can't jump to a row it hasn't laid out, so this homes in over a few frames until the row's `FindText` has built and revealed itself.
Future<void> revealListRow(
  DevToolsFind find,
  ScrollController controller, {
  required int index,
  required int count,
}) async {
  final version = find.revealVersion;
  for (var attempt = 0; attempt < 8; attempt++) {
    await SchedulerBinding.instance.endOfFrame;
    if (!find.revealPending || find.revealVersion != version) return;
    if (!controller.hasClients || count == 0) return;
    final position = controller.position;
    final extent = position.maxScrollExtent + position.viewportDimension;
    final estimate = extent * index / count - position.viewportDimension / 2;
    position.jumpTo(
      estimate.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }
}
