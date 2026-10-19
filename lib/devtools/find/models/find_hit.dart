import 'find_target.dart';

/// One occurrence of the search text.
class FindHit {
  const FindHit({
    required this.tab,
    required this.target,
    required this.occurrence,
  });

  /// The tab the match is in.
  final int tab;

  /// The text the match is in.
  final FindTarget target;

  /// Which match inside [target]'s text this is, counting from 0.
  final int occurrence;
}
