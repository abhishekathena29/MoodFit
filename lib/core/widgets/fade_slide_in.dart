import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Port of the `.animate-fade-in` CSS keyframe (`moodfit-slide-up`):
/// opacity 0→1 and translateY(20px)→0 over 800ms, same easing curve,
/// with an optional stagger delay (matches `[animation-delay:Nms]`).
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: kFadeInDuration);
    _t = CurvedAnimation(parent: _controller, curve: kFadeInCurve);
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        return Opacity(
          opacity: _t.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _t.value)),
            child: child,
          ),
        );
      },
    );
  }
}
