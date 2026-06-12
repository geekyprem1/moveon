import 'dart:math';
import 'package:flutter/material.dart';

class CelebrationOverlay extends StatefulWidget {
  final int currentXp;
  final VoidCallback onDismiss;

  const CelebrationOverlay({
    super.key,
    required this.currentXp,
    required this.onDismiss,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final List<_Sparkle> _sparkles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );

    // Generate sparkles
    _sparkles = List.generate(45, (index) => _createSparkle());

    _controller.addListener(() {
      setState(() {
        _updateSparkles();
      });
    });

    _controller.forward();
  }

  _Sparkle _createSparkle() {
    return _Sparkle(
      x: (_random.nextDouble() - 0.5) * 300,
      y: _random.nextDouble() * 200 + 100, // starts below center
      vx: (_random.nextDouble() - 0.5) * 2.5,
      vy: -(_random.nextDouble() * 3.5 + 2.0),
      size: _random.nextDouble() * 4 + 2,
      maxLife: 1.0,
      life: _random.nextDouble() * 0.3,
      color: Colors.amberAccent.withAlpha((_random.nextDouble() * 150 + 100).toInt()),
    );
  }

  void _updateSparkles() {
    double progress = _controller.value;
    for (var s in _sparkles) {
      if (progress > s.life) {
        s.x += s.vx;
        s.y += s.vy;
        s.vy += 0.05; // gravity pulls down slightly
        s.maxLife -= 0.012; // slow fade
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black.withAlpha(220),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Sparkle Particle field
            CustomPaint(
              size: size,
              painter: _SparklePainter(_sparkles, _controller.value),
            ),

            // Main content card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animating Glowing Ring
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.amber.shade400,
                          width: 4.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withAlpha(80),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '🕊️',
                          style: TextStyle(fontSize: 60),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Celebration Title
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Text(
                      'A Day of Grace Complete',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // XP Badge
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(38),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Colors.amber.shade400, width: 1.5),
                      ),
                      child: Text(
                        '✨ +15 HEALING XP EARNED',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.amber.shade300,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Supportive Copy
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'You held space for your Heart, Mind, and Body today. Every small, mindful choice is rebuilding your strength. Rest deeply, you are moving forward.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade400,
                        height: 1.5,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Dismiss Button
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onDismiss,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade400,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: const Text(
                          'Rest Deeply',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sparkle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double maxLife;
  double life;
  Color color;

  _Sparkle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.maxLife,
    required this.life,
    required this.color,
  });
}

class _SparklePainter extends CustomPainter {
  final List<_Sparkle> sparkles;
  final double progress;

  _SparklePainter(this.sparkles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2 - 50);

    for (var s in sparkles) {
      if (progress > s.life && s.maxLife > 0) {
        paint.color = s.color.withValues(alpha: s.maxLife);
        canvas.drawCircle(
          Offset(center.dx + s.x, center.dy + s.y),
          s.size * s.maxLife,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => true;
}
