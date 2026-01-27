import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vyana_flutter/core/theme.dart';

class MultiColorLoader extends StatefulWidget {
  final double size;
  final double strokeWidth;

  const MultiColorLoader({
    super.key,
    this.size = 24,
    this.strokeWidth = 3,
  });

  @override
  State<MultiColorLoader> createState() => _MultiColorLoaderState();
}

class _MultiColorLoaderState extends State<MultiColorLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: 2.seconds)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.size,
      width: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CircularProgressIndicator(
            strokeWidth: widget.strokeWidth,
            valueColor: _controller.drive(
              TweenSequence<Color?>([
                TweenSequenceItem(
                  tween: ColorTween(
                    begin: AppColors.primaryPurple,
                    end: AppColors.accentPink,
                  ),
                  weight: 25,
                ),
                TweenSequenceItem(
                  tween: ColorTween(
                    begin: AppColors.accentPink,
                    end: AppColors.accentCyan,
                  ),
                  weight: 25,
                ),
                TweenSequenceItem(
                  tween: ColorTween(
                    begin: AppColors.accentCyan,
                    end: AppColors.warmOrange,
                  ),
                  weight: 25,
                ),
                TweenSequenceItem(
                  tween: ColorTween(
                    begin: AppColors.warmOrange,
                    end: AppColors.primaryPurple,
                  ),
                  weight: 25,
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}
