import 'dart:math';
import 'package:flutter/material.dart';

class GeminiAnimatedBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final List<Color> gradientColors;
  final bool isParsing;

  const GeminiAnimatedBorder({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.borderWidth = 2.0,
    this.isParsing = false,
    this.gradientColors = const [
      Color(0xFF4285F4), // Blue
      Color(0xFF9B72CB), // Purple
      Color(0xFFD96570), // Pink/Red
    ],
  });

  @override
  State<GeminiAnimatedBorder> createState() => _GeminiAnimatedBorderState();
}

class _GeminiAnimatedBorderState extends State<GeminiAnimatedBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GeminiBorderPainter(
            animationValue: _controller.value,
            borderRadius: widget.borderRadius,
            borderWidth: widget.borderWidth,
            gradientColors: widget.gradientColors,
            isParsing: widget.isParsing,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _GeminiBorderPainter extends CustomPainter {
  final double animationValue;
  final double borderRadius;
  final double borderWidth;
  final List<Color> gradientColors;
  final bool isParsing;

  _GeminiBorderPainter({
    required this.animationValue,
    required this.borderRadius,
    required this.borderWidth,
    required this.gradientColors,
    required this.isParsing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);

    if (isParsing) {
      // Estado Carregando: Animação de rotação segmentada
      final double startAngle = animationValue * 4 * pi;
      
      final Paint paint = Paint()
        ..shader = SweepGradient(
          colors: [
            ...gradientColors,
            gradientColors.first.withValues(alpha: 0),
            Colors.transparent,
            gradientColors.first.withValues(alpha: 0),
            ...gradientColors,
          ],
          stops: const [
            0.0, 0.1, 0.4, 0.3, 0.5, 0.7, 0.8, 0.9, 1.0
          ],
          transform: GradientRotation(startAngle),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..strokeCap = StrokeCap.round;

      final Paint glowPaint = Paint()
        ..shader = paint.shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth * 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    } else {
      // Estado Inicial: Efeito "Breathing" em todo o perímetro
      // Usamos seno para criar o efeito pulsar (0 -> 1 -> 0)
      final double breath = (sin(animationValue * 2 * pi) + 1) / 2;
      final double opacity = 0.2 + (breath * 0.8);
      
      final Paint paint = Paint()
        ..shader = LinearGradient(
          colors: gradientColors.map((c) => c.withValues(alpha: opacity)).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..strokeCap = StrokeCap.round;

      final Paint glowPaint = Paint()
        ..shader = paint.shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth * 1.5
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + (breath * 4));

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GeminiBorderPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.isParsing != isParsing;
  }
}
