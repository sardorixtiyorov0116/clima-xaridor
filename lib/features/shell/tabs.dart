import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

/// Keyingi bosqichdagi bo'limlar uchun bo'sh holat.
class SoonTab extends StatelessWidget {
  const SoonTab({super.key, required this.title, required this.body, required this.icon});

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: c.surfaceMuted, shape: BoxShape.circle),
                child: Icon(icon, size: 42, color: c.textTertiary),
              ),
              const SizedBox(height: Space.xl),
              Text(s.soonTitle, style: context.text.titleLarge),
              const SizedBox(height: Space.sm),
              Text(body, textAlign: TextAlign.center, style: context.text.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
