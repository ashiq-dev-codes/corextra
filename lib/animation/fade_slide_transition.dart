import 'package:flutter/material.dart';

/// Directions for the slide animation in [FadeSlideTransition].
enum SlideDirection { top, left, right, bottom, custom }

/// A widget that combines fade and slide animations for smooth transitions.
///
/// It uses [AnimatedSwitcher] internally to animate between different child widgets.
/// You can specify the direction of the slide and a custom offset if needed.
///
/// Example usage:
/// ```dart
/// bool toggle = false;
///
/// ElevatedButton(
///   onPressed: () => setState(() => toggle = !toggle),
///   child: const Text('Toggle FadeSlideTransition'),
/// );
///
/// FadeSlideTransition(
///   direction: SlideDirection.bottom,
///   duration: Duration(milliseconds: 400),
///   child: toggle
///       ? Text('Hello from FadeSlideTransition', key: ValueKey('visible'))
///       : SizedBox.shrink(key: ValueKey('hidden')),
/// );
/// ```
class FadeSlideTransition extends StatelessWidget {
  const FadeSlideTransition({
    super.key,
    required this.child,
    this.customOffset = Offset.zero,
    this.direction = SlideDirection.bottom,
    this.duration = const Duration(milliseconds: 300),
  });

  /// The widget to display inside the transition.
  final Widget child;

  /// Duration of the animation.
  final Duration duration;

  /// Custom offset for the slide animation when [direction] is set to [SlideDirection.custom].
  final Offset customOffset;

  /// The direction in which the child will slide in/out.
  final SlideDirection direction;

  @override
  Widget build(BuildContext context) {
    /// Returns the starting offset for the slide animation based on [direction].
    Offset getBeginOffset() {
      switch (direction) {
        case SlideDirection.left:
          return const Offset(-0.2, 0);
        case SlideDirection.right:
          return const Offset(0.2, 0);
        case SlideDirection.top:
          return const Offset(0, -0.2);
        case SlideDirection.bottom:
          return const Offset(0, 0.2);
        case SlideDirection.custom:
          return customOffset;
      }
    }

    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (widget, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: getBeginOffset(),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: widget),
        );
      },
      child: child,
    );
  }
}
