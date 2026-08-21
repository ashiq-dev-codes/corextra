/// Current resident set size in bytes. Always `null` on platforms
/// without `dart:io` (e.g. web).
int? currentRssBytes() => null;
