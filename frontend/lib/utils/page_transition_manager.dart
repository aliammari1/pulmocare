import 'package:flutter/material.dart';

enum PageTransitionType {
  slide,
  fade,
  scale,
  rotation,
  slideUp,
}

class PageTransitionManager extends PageRouteBuilder {
  final Widget page;
  final PageTransitionType type;
  final Duration duration;
  final Curve curve;

  PageTransitionManager({
    required this.page,
    this.type = PageTransitionType.slide,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );

            switch (type) {
              case PageTransitionType.slide:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                );
              case PageTransitionType.fade:
                return FadeTransition(
                  opacity: curvedAnimation,
                  child: child,
                );
              case PageTransitionType.scale:
                return ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.9,
                    end: 1.0,
                  ).animate(curvedAnimation),
                  child: FadeTransition(
                    opacity: curvedAnimation,
                    child: child,
                  ),
                );
              case PageTransitionType.rotation:
                return RotationTransition(
                  turns: Tween<double>(
                    begin: 0.25,
                    end: 1.0,
                  ).animate(curvedAnimation),
                  child: ScaleTransition(
                    scale: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  ),
                );
              case PageTransitionType.slideUp:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                );
            }
          },
        );
}