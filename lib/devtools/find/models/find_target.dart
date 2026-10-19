/// One piece of text a DevTools tab can show, as handed to the find bar.
class FindTarget {
  const FindTarget(this.id, this.text, [this.meta]);

  /// The `FindText.id` that renders [text], so a match can be found on screen again once it's built.
  final String id;

  /// The text to search.
  final String text;

  /// Whatever the owning view needs to bring [text] on screen, like which request and section it lives in.
  final Object? meta;
}
