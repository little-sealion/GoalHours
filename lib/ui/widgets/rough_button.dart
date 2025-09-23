import 'package:flutter/material.dart';
import 'package:rough_flutter/rough_flutter.dart';

class RoughButton extends StatelessWidget {
  const RoughButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.fillColor,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    this.roughness = 2.0,
    this.borderWidth = 2.0,
    this.hachureGap = 8,
    this.hachureAngle = -20,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData? icon;
  final Color? fillColor;
  final Color? borderColor;
  final EdgeInsets padding;
  final double roughness;
  final double borderWidth;
  final double hachureGap;
  final double hachureAngle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = fillColor ?? scheme.primaryContainer;
    final fg = scheme.onPrimaryContainer;
    final stroke = borderColor ?? scheme.outline;

    final drawConfig = DrawConfig.build(
      roughness: roughness,
      curveStepCount: 9,
    );
    final fillerConfig = FillerConfig.build(
      hachureGap: hachureGap,
      hachureAngle: hachureAngle,
      drawConfig: drawConfig,
    );

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: padding,
        decoration: RoughBoxDecoration(
          shape: RoughBoxShape.rectangle,
          borderStyle: RoughDrawingStyle(
            width: borderWidth,
            color: stroke,
          ),
          fillStyle: RoughDrawingStyle(
            color: bg,
          ),
          filler: HachureFiller(fillerConfig),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
