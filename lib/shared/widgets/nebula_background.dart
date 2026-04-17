// lib/shared/widgets/nebula_background.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A reusable nebula/starfield background widget.
/// Wrap any screen's body with this for the cosmic effect.
class NebulaBackground extends StatefulWidget {
  const NebulaBackground({
    super.key,
    required this.child,
    this.showNebula = true,
  });

  final Widget child;
  final bool showNebula;

  @override
  State<NebulaBackground> createState() => _NebulaBackgroundState();
}

class _NebulaBackgroundState extends State<NebulaBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Deep space background
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return CustomPaint(
                painter: _NebulaPainter(
                  progress: _controller.value,
                  isDark: isDark,
                  showNebula: widget.showNebula,
                ),
              );
            },
          ),
        ),
        // Content on top
        widget.child,
      ],
    );
  }
}

class _NebulaPainter extends CustomPainter {
  _NebulaPainter({
    required this.progress,
    required this.isDark,
    required this.showNebula,
  });

  final double progress;
  final bool isDark;
  final bool showNebula;

  static final _rand = math.Random(42);
  static late final List<_Star> _stars = _generateStars();

  static List<_Star> _generateStars() {
    final stars = <_Star>[];
    // Small dim stars
    for (int i = 0; i < 80; i++) {
      stars.add(_Star(
        x: _rand.nextDouble(),
        y: _rand.nextDouble(),
        size: _rand.nextDouble() * 1.2 + 0.3,
        opacity: _rand.nextDouble() * 0.5 + 0.2,
        twinkleOffset: _rand.nextDouble(),
      ));
    }
    // Brighter stars
    for (int i = 0; i < 25; i++) {
      stars.add(_Star(
        x: _rand.nextDouble(),
        y: _rand.nextDouble(),
        size: _rand.nextDouble() * 2.0 + 1.2,
        opacity: _rand.nextDouble() * 0.4 + 0.5,
        twinkleOffset: _rand.nextDouble(),
        isBright: true,
      ));
    }
    return stars;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Paint background
    if (isDark) {
      _paintDarkBackground(canvas, size);
    } else {
      _paintLightBackground(canvas, size);
    }

    // Paint nebula clouds
    if (showNebula) {
      _paintNebulaClouds(canvas, size);
    }

    // Paint stars
    _paintStars(canvas, size);

    // Paint constellation lines
    _paintConstellations(canvas, size);
  }

  void _paintDarkBackground(Canvas canvas, Size size) {
    final paint = Paint();

    // Base deep space gradient
    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF050210),
        const Color(0xFF0A0520),
        const Color(0xFF080318),
        const Color(0xFF040112),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _paintLightBackground(Canvas canvas, Size size) {
    final paint = Paint();

    // Soft cosmic light background
    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFEEE8FF),
        const Color(0xFFF5F0FF),
        const Color(0xFFECE4FF),
        const Color(0xFFF0EBFF),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _paintNebulaClouds(Canvas canvas, Size size) {
    final breathe = math.sin(progress * math.pi) * 0.15 + 0.85;

    if (isDark) {
      // Purple nebula cloud top-right
      _drawNebulaCloud(
        canvas, size,
        center: Offset(size.width * 0.75, size.height * 0.18),
        radius: size.width * 0.45 * breathe,
        color: const Color(0xFF5B21B6).withOpacity(0.18),
      );
      // Cyan/teal nebula cloud left
      _drawNebulaCloud(
        canvas, size,
        center: Offset(size.width * 0.15, size.height * 0.6),
        radius: size.width * 0.38,
        color: const Color(0xFF0891B2).withOpacity(0.12),
      );
      // Pink nebula accent
      _drawNebulaCloud(
        canvas, size,
        center: Offset(size.width * 0.5, size.height * 0.85),
        radius: size.width * 0.3 * breathe,
        color: const Color(0xFF9D174D).withOpacity(0.10),
      );
      // Deep blue nebula band
      _drawNebulaCloud(
        canvas, size,
        center: Offset(size.width * 0.3, size.height * 0.35),
        radius: size.width * 0.5,
        color: const Color(0xFF1E3A8A).withOpacity(0.08),
      );
    } else {
      // Light mode: soft pastel nebula clouds
      _drawNebulaCloud(
        canvas, size,
        center: Offset(size.width * 0.8, size.height * 0.15),
        radius: size.width * 0.45,
        color: const Color(0xFF7C3AED).withOpacity(0.06),
      );
      _drawNebulaCloud(
        canvas, size,
        center: Offset(size.width * 0.1, size.height * 0.7),
        radius: size.width * 0.4,
        color: const Color(0xFF0EA5E9).withOpacity(0.05),
      );
      _drawNebulaCloud(
        canvas, size,
        center: Offset(size.width * 0.55, size.height * 0.9),
        radius: size.width * 0.35,
        color: const Color(0xFFDB2777).withOpacity(0.04),
      );
    }
  }

  void _drawNebulaCloud(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color,
          color.withOpacity(color.opacity * 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  void _paintStars(Canvas canvas, Size size) {
    for (final star in _stars) {
      final twinkle = math.sin(
            (progress + star.twinkleOffset) * math.pi * 2,
          ) *
          0.3 +
          0.7;

      final opacity = star.isBright
          ? (isDark ? star.opacity * twinkle : star.opacity * 0.4 * twinkle)
          : (isDark ? star.opacity * twinkle : star.opacity * 0.25 * twinkle);

      Color starColor;
      if (star.isBright) {
        // Colored stars: blue-white, yellow, or slight cyan
        final colorChoice = (_stars.indexOf(star) % 3);
        if (colorChoice == 0) {
          starColor = Color.lerp(Colors.white, const Color(0xFFB0E0FF), 0.4)!
              .withOpacity(opacity);
        } else if (colorChoice == 1) {
          starColor = Color.lerp(Colors.white, const Color(0xFFFFF9E0), 0.3)!
              .withOpacity(opacity);
        } else {
          starColor = Colors.white.withOpacity(opacity);
        }
      } else {
        starColor = Colors.white.withOpacity(opacity);
      }

      final paint = Paint()..color = starColor;

      if (star.isBright && isDark) {
        // Draw 4-point star shape for bright stars
        _draw4PointStar(
          canvas,
          Offset(star.x * size.width, star.y * size.height),
          star.size * 1.5,
          paint,
        );
      } else {
        canvas.drawCircle(
          Offset(star.x * size.width, star.y * size.height),
          star.size,
          paint,
        );
      }
    }
  }

  void _draw4PointStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size * 0.25, center.dy - size * 0.25);
    path.lineTo(center.dx + size, center.dy);
    path.lineTo(center.dx + size * 0.25, center.dy + size * 0.25);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size * 0.25, center.dy + size * 0.25);
    path.lineTo(center.dx - size, center.dy);
    path.lineTo(center.dx - size * 0.25, center.dy - size * 0.25);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _paintConstellations(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.07)
          : const Color(0xFF6C3DE1).withOpacity(0.08)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.25)
          : const Color(0xFF6C3DE1).withOpacity(0.3);

    // Orion-like constellation top right
    final List<Offset> orion = [
      Offset(size.width * 0.72, size.height * 0.08),
      Offset(size.width * 0.78, size.height * 0.12),
      Offset(size.width * 0.74, size.height * 0.17),
      Offset(size.width * 0.80, size.height * 0.22),
      Offset(size.width * 0.76, size.height * 0.28),
    ];
    _drawConstellation(canvas, orion, linePaint, dotPaint);

    // Small constellation bottom left
    final List<Offset> mini = [
      Offset(size.width * 0.08, size.height * 0.75),
      Offset(size.width * 0.13, size.height * 0.70),
      Offset(size.width * 0.18, size.height * 0.73),
      Offset(size.width * 0.14, size.height * 0.78),
    ];
    _drawConstellation(canvas, mini, linePaint, dotPaint);

    // Dipper-like shape middle area
    final List<Offset> dipper = [
      Offset(size.width * 0.35, size.height * 0.42),
      Offset(size.width * 0.40, size.height * 0.40),
      Offset(size.width * 0.45, size.height * 0.43),
      Offset(size.width * 0.48, size.height * 0.48),
      Offset(size.width * 0.44, size.height * 0.52),
    ];
    _drawConstellation(canvas, dipper, linePaint, dotPaint);
  }

  void _drawConstellation(
    Canvas canvas,
    List<Offset> points,
    Paint linePaint,
    Paint dotPaint,
  ) {
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }
    for (final p in points) {
      canvas.drawCircle(p, 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_NebulaPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}

class _Star {
  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.twinkleOffset,
    this.isBright = false,
  });

  final double x;
  final double y;
  final double size;
  final double opacity;
  final double twinkleOffset;
  final bool isBright;
}
