import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/haptic_service.dart';

class BurningAnimation extends ConsumerStatefulWidget {
  final String title;
  final String content;
  final VoidCallback onComplete;

  const BurningAnimation({
    super.key,
    required this.title,
    required this.content,
    required this.onComplete,
  });

  @override
  ConsumerState<BurningAnimation> createState() => _BurningAnimationState();
}

class _BurningAnimationState extends ConsumerState<BurningAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final Random _random = Random();
  bool _releasedTextVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _particles = List.generate(120, (index) => _createParticle());

    _controller.addListener(() {
      setState(() {
        _updateParticles();
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        ref.read(hapticServiceProvider).selection();
        setState(() {
          _releasedTextVisible = true;
        });
        Future.delayed(const Duration(seconds: 2), () {
          widget.onComplete();
        });
      }
    });

    // Subtle delay, medium impact, matching the fade animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(hapticServiceProvider).medium();
      }
    });

    _controller.forward();
  }

  _Particle _createParticle() {
    return _Particle(
      x: _random.nextDouble() * 280 - 140, // Centered range
      y: _random.nextDouble() * 200 + 100, // Starts near bottom of card
      vx: (_random.nextDouble() - 0.5) * 1.5,
      vy: -(_random.nextDouble() * 2 + 1.5),
      size: _random.nextDouble() * 3 + 2,
      life: _random.nextDouble() * 0.4, // delayed start
      maxLife: 1.0,
      color: _random.nextBool()
          ? Colors.orangeAccent.withValues(alpha: 0.8)
          : Colors.redAccent.withValues(alpha: 0.8),
    );
  }

  void _updateParticles() {
    double progress = _controller.value;
    for (var p in _particles) {
      if (progress > p.life) {
        p.x += p.vx;
        p.y += p.vy;
        p.vy -= 0.05; // accelerate upward
        p.vx += (progress - 0.5) * 0.1; // swirl effect
        p.maxLife -= 0.015;
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
    final double scale = 1.0 - _controller.value;
    final double opacity = max(0.0, 1.0 - _controller.value * 1.5);
    final double progress = _controller.value;

    // Heat border glow
    final Color glowColor = Color.lerp(
      Colors.transparent,
      Colors.orange.shade700,
      min(1.0, progress * 2),
    )!;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: _releasedTextVisible
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🕊️',
                      style: TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You released this emotion.',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Let it drift away. You are moving forward.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    // Spark Particles
                    if (progress > 0.1)
                      CustomPaint(
                        size: const Size(300, 500),
                        painter: _SparksPainter(_particles, progress),
                      ),

                    // The burning letter
                    Transform.scale(
                      scale: max(0.0, scale),
                      alignment: Alignment.topCenter,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 300, maxHeight: 450),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: glowColor,
                              width: 3.0 + progress * 5.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: glowColor.withValues(alpha: 0.6),
                                blurRadius: 20 + progress * 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title.isEmpty ? 'Untitled Letter' : widget.title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(color: Colors.grey),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      widget.content,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: Colors.grey.shade300,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.red.shade400, width: 1.0),
                                    ),
                                    child: Text(
                                      'BURNING...',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: Colors.red.shade300,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double life;
  double maxLife;
  Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
    required this.maxLife,
    required this.color,
  });
}

class _SparksPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _SparksPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2 + 100);

    for (var p in particles) {
      if (progress > p.life && p.maxLife > 0) {
        paint.color = p.color.withValues(alpha: p.maxLife);
        canvas.drawCircle(
          Offset(center.dx + p.x, center.dy + p.y),
          p.size * p.maxLife,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparksPainter oldDelegate) => true;
}
