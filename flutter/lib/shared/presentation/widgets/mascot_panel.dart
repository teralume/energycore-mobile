import 'package:flutter/material.dart';

class MascotPanel extends StatelessWidget {
  const MascotPanel({
    super.key,
    required this.title,
    required this.message,
    this.compact = false,
  });

  final String title;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$title. $message',
      child: Container(
        padding: EdgeInsets.all(compact ? 18 : 26),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF07170E),
              scheme.primary.withValues(alpha: 0.14),
              const Color(0xFF161708),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.38)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.asset(
                'assets/images/energycore-mascot.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFFF4F7F5),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFC6D0C9), height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
