import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.onRetry, this.visible = true});

  final VoidCallback onRetry;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final strings = context.strings;
    return Material(
      color: const Color(0xFF4A2A00),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
          child: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Color(0xFFFFD18A)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.text('offline'),
                  style: const TextStyle(
                    color: Color(0xFFFFE8C2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(strings.text('retry')),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFFD18A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
