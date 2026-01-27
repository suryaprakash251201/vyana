import 'package:flutter/material.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'dart:math' as math;

class HexagonButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final String label;
  final Color color;
  final bool isSelected;

  const HexagonButton({
    super.key,
    required this.onTap,
    required this.child,
    required this.label,
    this.color = SciFiColors.cyan,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: CustomPaint(
            painter: HexagonPainter(
              color: color,
              paintingStyle: isSelected ? PaintingStyle.fill : PaintingStyle.stroke,
            ),
            child: Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              child: isSelected 
                ? ColorFiltered(
                    colorFilter: ColorFilter.mode(SciFiColors.background, BlendMode.srcIn),
                    child: child,
                  )
                : child,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isSelected ? color : color.withOpacity(0.7),
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron', // Assuming Orbitron is applied globally or here
          ),
        ),
      ],
    );
  }
}

class HexagonPainter extends CustomPainter {
  final Color color;
  final PaintingStyle paintingStyle;

  HexagonPainter({required this.color, required this.paintingStyle});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = paintingStyle;

    if (paintingStyle == PaintingStyle.stroke) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
    }

    final path = Path();
    final w = size.width;
    final h = size.height;
    
    // Hexagon points
    path.moveTo(w * 0.5, 0); // Top Center
    path.lineTo(w, h * 0.25); // Top Right
    path.lineTo(w, h * 0.75); // Bottom Right
    path.lineTo(w * 0.5, h); // Bottom Center
    path.lineTo(0, h * 0.75); // Bottom Left
    path.lineTo(0, h * 0.25); // Top Left
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CyberContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Color borderColor;

  const CyberContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderColor = SciFiColors.cyan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: SciFiColors.surface.withOpacity(0.5),
        border: Border(
          left: BorderSide(color: borderColor, width: 2),
          right: BorderSide(color: borderColor, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Stack(
        children: [
          child,
          Positioned(
            top: 0,
            left: 0,
            child: _CornerAccent(color: borderColor),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Transform.rotate(
              angle: math.pi,
              child: _CornerAccent(color: borderColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerAccent extends StatelessWidget {
  final Color color;

  const _CornerAccent({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: color, width: 2),
          left: BorderSide(color: color, width: 2),
        ),
      ),
    );
  }
}

class GlitchText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const GlitchText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? const TextStyle();
    return Stack(
      children: [
        Transform.translate(
          offset: const Offset(-2, 0),
          child: Text(
            text,
            style: baseStyle.copyWith(color: SciFiColors.cyan.withOpacity(0.8)),
          ),
        ),
        Transform.translate(
          offset: const Offset(2, 0),
          child: Text(
            text,
            style: baseStyle.copyWith(color: SciFiColors.purple.withOpacity(0.8)),
          ),
        ),
        Text(
          text,
          style: baseStyle.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}
