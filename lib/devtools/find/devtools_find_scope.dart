import 'package:flutter/widgets.dart';

import 'devtools_find.dart';

/// Shares a panel's [DevToolsFind] with every view below it; read it with `DevToolsFind.maybeOf`.
class DevToolsFindScope extends InheritedNotifier<DevToolsFind> {
  const DevToolsFindScope({
    super.key,
    required DevToolsFind find,
    required super.child,
  }) : super(notifier: find);
}
