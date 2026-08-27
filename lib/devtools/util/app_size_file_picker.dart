import 'package:file_selector/file_selector.dart';

/// Opens the platform's native file picker restricted to `.json` files; a standalone function so `AppSizeTab.pickFile` can be swapped for a fake in tests.
Future<XFile?> openAppSizeAnalysisFile() {
  const typeGroup = XTypeGroup(
    label: 'Size analysis JSON',
    extensions: ['json'],
  );
  return openFile(acceptedTypeGroups: [typeGroup]);
}
