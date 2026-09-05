import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: 'EnergyCore',
      image: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(compact ? 12 : 15),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 20),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(compact ? 9 : 11),
              child: Icon(
                Icons.bolt_rounded,
                color: const Color(0xFF041409),
                size: compact ? 22 : 27,
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 12),
            Text(
              'EnergyCore',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
