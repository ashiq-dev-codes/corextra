import 'package:flutter/material.dart';

class FadeSlideTransition extends StatelessWidget {
  const FadeSlideTransition({
    super.key,
    required this.child,
  });
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300), // Fade-in duration
      transitionBuilder: (widget, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2), // Start slightly below
            end: const Offset(0, 0), // End at normal position
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: widget,
          ),
        );
      },
      child: child,
    );
  }
}
