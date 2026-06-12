import 'dart:math' as math;
import 'package:flutter/material.dart';

class HealingOrb extends StatefulWidget {
  final bool isMini;
  final bool isTyping;

  const HealingOrb({
    super.key,
    this.isMini = false,
    this.isTyping = false,
  });

  @override
  State<HealingOrb> createState() => _HealingOrbState();
}

class _HealingOrbState extends State<HealingOrb> with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _morphController;

  @override
  void initState() {
    super.initState();
    // 6-second standard breathing cycle (Inhale 2s, Hold 2s, Exhale 2s)
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // 12-second slow morphing cycle
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant HealingOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTyping != oldWidget.isTyping) {
      if (widget.isTyping) {
        _breathingController.duration = const Duration(seconds: 3); // Faster cycle when active
        _morphController.duration = const Duration(seconds: 4);
      } else {
        _breathingController.duration = const Duration(seconds: 6);
        _morphController.duration = const Duration(seconds: 12);
      }
      _breathingController.repeat();
      _morphController.repeat();
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _morphController.dispose();
    super.dispose();
  }

  String get _breathingText {
    final val = _breathingController.value;
    if (val < 0.333) {
      return "Inhale";
    } else if (val < 0.666) {
      return "Hold";
    } else {
      return "Exhale";
    }
  }

  double get _breathingScale {
    final val = _breathingController.value;
    if (val < 0.333) {
      // Scale up from 1.0 to 1.15
      final progress = val / 0.333;
      return 1.0 + (progress * 0.15);
    } else if (val < 0.666) {
      // Hold at 1.15
      return 1.15;
    } else {
      // Scale down from 1.15 to 1.0
      final progress = (val - 0.666) / 0.334;
      return 1.15 - (progress * 0.15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = widget.isMini ? 40.0 : 160.0;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_breathingController, _morphController]),
      builder: (context, child) {
        // Subtle translation offset to make it "float" bobbing up and down
        final floatOffset = math.sin(_morphController.value * 2 * math.pi) * (widget.isMini ? 2.0 : 8.0);
        // Breathing scale factor driven by Calm-inspired phases
        final scale = _breathingScale;

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Layer 1: Glow backdrop
                  Container(
                    width: size * 0.9,
                    height: size * 0.9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC76D8A).withValues(alpha: widget.isMini ? 0.3 : 0.4),
                          blurRadius: widget.isMini ? 12 : 45,
                          spreadRadius: widget.isMini ? 2 : 10,
                        ),
                        BoxShadow(
                          color: const Color(0xFFBA68C8).withValues(alpha: widget.isMini ? 0.15 : 0.25),
                          blurRadius: widget.isMini ? 8 : 30,
                          spreadRadius: widget.isMini ? 0 : 5,
                        ),
                      ],
                    ),
                  ),
                  
                  // Layer 2: Custom Fluid Painter
                  CustomPaint(
                    size: Size(size, size),
                    painter: OrbPainter(
                      morphValue: _morphController.value,
                      primaryColor: const Color(0xFFC76D8A),
                      secondaryColor: const Color(0xFFBA68C8),
                      accentColor: const Color(0xFFFFE4E1),
                      isMini: widget.isMini,
                    ),
                  ),

                  // Layer 3: Breathing Text Overlay (only for full-size orb)
                  if (!widget.isMini)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _breathingText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Breathe",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.secondary.withValues(alpha: 0.65),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class OrbPainter extends CustomPainter {
  final double morphValue;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final bool isMini;

  OrbPainter({
    required this.morphValue,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.isMini,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw three morphing layers with varying speeds, wave counts, and opacities
    _drawLayer(canvas, center, maxRadius * 0.85, 3, 0.0, 0.4, [
      primaryColor.withValues(alpha: 0.55),
      secondaryColor.withValues(alpha: 0.4),
    ]);

    _drawLayer(canvas, center, maxRadius * 0.75, 4, math.pi * 0.5, 0.55, [
      secondaryColor.withValues(alpha: 0.6),
      accentColor.withValues(alpha: 0.35),
    ]);

    _drawLayer(canvas, center, maxRadius * 0.65, 5, math.pi * 1.1, 0.7, [
      primaryColor.withValues(alpha: 0.7),
      accentColor.withValues(alpha: 0.5),
    ]);
  }

  void _drawLayer(
    Canvas canvas,
    Offset center,
    double baseRadius,
    int waveCount,
    double phaseShift,
    double opacity,
    List<Color> gradientColors,
  ) {
    final path = Path();
    final steps = 40;
    final stepAngle = (2 * math.pi) / steps;
    
    // Wave amplitude relative to size
    final amplitude = isMini ? baseRadius * 0.06 : baseRadius * 0.12;

    for (int i = 0; i <= steps; i++) {
      final angle = i * stepAngle;
      
      // Dynamic offset driven by morph value and angle
      final waveOffset = math.sin((waveCount * angle) + (morphValue * 2 * math.pi) + phaseShift) * amplitude;
      final currentRadius = baseRadius + waveOffset;

      final x = center.dx + currentRadius * math.cos(angle);
      final y = center.dy + currentRadius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final paint = Paint()
      ..shader = RadialGradient(
        colors: gradientColors,
        stops: const [0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 1.2))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant OrbPainter oldDelegate) {
    return oldDelegate.morphValue != morphValue ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isMini != isMini;
  }
}
