import 'package:flutter/material.dart';

enum SlideDirection { top, left, right, bottom, custom }

class FadeSlideTransition extends StatelessWidget {
  const FadeSlideTransition({
    super.key,
    required this.child,
    this.customOffset = Offset.zero,
    this.direction = SlideDirection.bottom,
    this.duration = const Duration(milliseconds: 300),
  });
  final Widget child;
  final Duration duration;
  final Offset customOffset;
  final SlideDirection direction;

  @override
  Widget build(BuildContext context) {
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
