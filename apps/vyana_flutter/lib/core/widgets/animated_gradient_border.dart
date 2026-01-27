import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vyana_flutter/core/theme.dart';

class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final double borderWidth;
  final BorderRadius borderRadius;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    this.isActive = false,
    this.borderWidth = 2,
    this.borderRadius = const BorderRadius.all(Radius.circular(50)),
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: 3.seconds)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: SweepGradient(
              colors: const [
                AppColors.primaryPurple,
                AppColors.accentCyan,
                AppColors.accentPink,
                AppColors.warmOrange,
                AppColors.primaryPurple,
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              transform: GradientRotation(_controller.value * 2 * 3.14159),
            ),
          ),
          padding: EdgeInsets.all(widget.borderWidth),
          child: widget.child,
        );
      },
    );
  }
}
