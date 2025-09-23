import 'package:flutter/material.dart';
import 'package:rough_flutter/rough_flutter.dart';

class RoughProgressBar extends StatelessWidget {
  const RoughProgressBar({
    super.key,
    required this.fraction,
    required this.color,
    this.height = 14,
    this.width,
  });

  final double fraction; // 0..1 (can exceed but we clamp visually)
  final Color color;
  final double height;
  final double? width; // if null, expands to max width

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = scheme.surfaceContainerHighest;
    final outline = scheme.outline;
    final clamped = fraction.isNaN ? 0.0 : fraction.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
    final maxW = width ?? constraints.maxWidth;
    // Inset so the fill doesn't overlap the rough outline strokes
    const inset = 3.0;
    final innerW = (maxW - inset * 2).clamp(0.0, double.infinity);
    final minVisible = 6.0; // ensure small but visible fill when > 0
    final fillW = clamped == 0
      ? 0.0
      : (clamped * innerW).clamp(minVisible, innerW);

        return SizedBox(
          height: height,
          width: maxW.isFinite ? maxW : double.infinity,
          child: Stack(
            children: [
              // Background bar with rough outline
              Positioned.fill(
                child: DecoratedBox(
                  decoration: RoughBoxDecoration(
                    shape: RoughBoxShape.rectangle,
                    borderStyle: RoughDrawingStyle(width: 2, color: outline),
                    fillStyle: RoughDrawingStyle(color: bg),
                  ),
                ),
              ),
              // Filled portion
              if (fillW > 0)
                Positioned(
                  left: inset,
                  top: inset,
                  bottom: inset,
                  width: fillW,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
