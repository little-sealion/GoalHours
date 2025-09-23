import 'package:flutter/material.dart';
import 'package:rough_flutter/rough_flutter.dart';

class RoughCard extends StatelessWidget {
  const RoughCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor = const Color(0xFF1E1E1E),
    this.fillColor,
    this.borderWidth = 2.0,
    this.roughness = 2.0,
    this.hachureGap = 8,
    this.hachureAngle = -20,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color borderColor;
  final Color? fillColor;
  final double borderWidth;
  final double roughness;
  final double hachureGap;
  final double hachureAngle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = fillColor ?? scheme.surface;

    final drawConfig = DrawConfig.build(
      roughness: roughness,
      curveStepCount: 9,
    );
    final fillerConfig = FillerConfig.build(
      hachureGap: hachureGap,
      hachureAngle: hachureAngle,
      drawConfig: drawConfig,
    );

    return Container(
      padding: padding,
      decoration: RoughBoxDecoration(
        shape: RoughBoxShape.rectangle,
        borderStyle: RoughDrawingStyle(
          width: borderWidth,
          color: borderColor,
        ),
        fillStyle: RoughDrawingStyle(
          color: bg,
        ),
        filler: HachureFiller(fillerConfig),
      ),
      child: child,
    );
  }
}
