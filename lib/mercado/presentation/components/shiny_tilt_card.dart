import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_comprinhas/core/config/app_settings_service.dart';
import 'package:flutter_comprinhas/core/config/service_locator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ShinyTiltCard extends StatefulWidget {
  final bool effectsEnabled;
  final Widget child;
  final BorderRadius borderRadius;
  final List<Color> baseColors;

  const ShinyTiltCard({
    super.key,
    required this.effectsEnabled,
    required this.child,
    required this.borderRadius,
    required this.baseColors,
  });

  @override
  State<ShinyTiltCard> createState() => _ShinyTiltCardState();
}

class _ShinyTiltCardState extends State<ShinyTiltCard> {
  static const double _gradientMotionMultiplier = 1.45;

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  Offset _gradientOffset = Offset.zero;
  bool _hasSensorEvent = false;
  double _debugX = 0;
  double _debugY = 0;

  @override
  void initState() {
    super.initState();
    if (widget.effectsEnabled) {
      _startEffects();
    }
  }

  @override
  void didUpdateWidget(covariant ShinyTiltCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.effectsEnabled == widget.effectsEnabled) return;

    if (widget.effectsEnabled) {
      _startEffects();
    } else {
      _stopEffects(reset: true);
    }
  }

  void _startEffects() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (!mounted) return;

      final normalizedX = (event.x / 9.8).clamp(-1.0, 1.0);
      final normalizedY = ((event.y / 9.8) - 0.77).clamp(-1.0, 1.0);
      final diagonalX = ((normalizedX * 1.2) + (normalizedY * 0.08)).clamp(
        -1.0,
        1.0,
      );
      final diagonalY = ((normalizedY * 0.35) - (normalizedX * 0.10)).clamp(
        -1.0,
        1.0,
      );
      final targetOffset = Offset(
        diagonalX * 138 * _gradientMotionMultiplier,
        diagonalY * 138 * _gradientMotionMultiplier,
      );

      setState(() {
        _hasSensorEvent = true;
        _debugX = normalizedX;
        _debugY = normalizedY;
        _gradientOffset = Offset(
          lerpDouble(_gradientOffset.dx, targetOffset.dx, 0.35)!,
          lerpDouble(_gradientOffset.dy, targetOffset.dy, 0.35)!,
        );
      });
    });
  }

  void _stopEffects({required bool reset}) {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;

    if (reset && mounted) {
      setState(() {
        _hasSensorEvent = false;
        _debugX = 0;
        _debugY = 0;
        _gradientOffset = Offset.zero;
      });
    }
  }

  @override
  void dispose() {
    _stopEffects(reset: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final developerModeEnabled = sl<AppSettingsService>().developerModeEnabled;

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SlidingGradientPainter(
                offset: _gradientOffset,
                colors: widget.baseColors,
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: developerModeEnabled,
            builder: (context, enabled, _) {
              if (!enabled) return const SizedBox.shrink();

              return Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _hasSensorEvent
                        ? 'x ${_debugX.toStringAsFixed(2)} | y ${_debugY.toStringAsFixed(2)}'
                        : 'sem sensor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _SlidingGradientPainter extends CustomPainter {
  final Offset offset;
  final List<Color> colors;

  const _SlidingGradientPainter({required this.offset, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final baseRect = Rect.fromCenter(
      center: Offset(size.width / 2 + offset.dx, size.height / 2 + offset.dy),
      width: size.width * 1.08,
      height: size.height * 1.08,
    );

    final basePaint =
        Paint()
          ..shader = LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(baseRect);

    canvas.drawRect(Offset.zero & size, basePaint);

    final shineRect = Rect.fromCenter(
      center: Offset(
        size.width / 2 + offset.dx * 1.15,
        size.height / 2 + offset.dy * 1.15,
      ),
      width: size.width * 1.18,
      height: size.height * 1.18,
    );

    final shinePaint =
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.28, 0.5, 0.72, 1.0],
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.16),
              Colors.white.withValues(alpha: 0.0),
              Colors.transparent,
            ],
          ).createShader(shineRect);

    canvas.drawRect(Offset.zero & size, shinePaint);
  }

  @override
  bool shouldRepaint(covariant _SlidingGradientPainter oldDelegate) {
    return oldDelegate.offset != offset || oldDelegate.colors != colors;
  }
}
