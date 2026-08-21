import 'dart:io';

/// Current resident set size in bytes, or `null` if unavailable.
int? currentRssBytes() {
  try {
    return ProcessInfo.currentRss;
  } catch (_) {
    return null;
  }
}
