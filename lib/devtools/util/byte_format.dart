/// Formats [bytes] as a human-readable size (e.g. "238.6 MB"), matching the units Flutter DevTools' own App Size tool uses.
String formatBytes(int bytes, {int decimals = 1}) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  final digits = unitIndex == 0 ? 0 : decimals;
  return '${value.toStringAsFixed(digits)} ${units[unitIndex]}';
}
