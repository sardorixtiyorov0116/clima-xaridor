import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/buttons.dart';
import '../../l10n/app_localizations.dart';

class LanguageOption {
  const LanguageOption(this.locale, this.native, this.hint);
  final Locale locale;
  final String native;
  final String hint;
}

const languageOptions = [
  LanguageOption(Locale('uz'), 'Oʻzbekcha', 'Узбекский · Uzbek'),
  LanguageOption(Locale('ru'), 'Русский', 'Rus tili · Russian'),
  LanguageOption(Locale('en'), 'English', 'Ingliz tili · Английский'),
];

/// Birinchi ochilishda — til tanlash. Tanlov darhol qo'llanadi.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final c = context.colors;
    final current = ref.watch(localeProvider) ?? Localizations.localeOf(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: Space.xl),
              const BrandLockup(height: 34),
              const Spacer(flex: 2),
              Text(s.langTitle, style: context.text.headlineMedium),
              const SizedBox(height: Space.sm),
              Text(s.langSubtitle, style: context.text.bodyMedium),
              const SizedBox(height: Space.xl),
              for (final o in languageOptions) ...[
                LanguageTile(
                  option: o,
                  selected: o.locale.languageCode == current.languageCode,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(localeProvider.notifier).set(o.locale);
                  },
                ),
                const SizedBox(height: Space.md),
              ],
              const Spacer(flex: 3),
              PrimaryButton(
                label: s.continueAction,
                onPressed: () {
                  // Tanlanmagan bo'lsa ham ekrandagi tilni saqlaymiz.
                  ref.read(localeProvider.notifier).set(Locale(current.languageCode));
                  context.go('/onboarding');
                },
              ),
              const SizedBox(height: Space.lg),
              Center(child: Text(s.tagline, style: context.text.bodySmall)),
              const SizedBox(height: Space.lg),
            ],
          ),
        ),
      ),
      backgroundColor: c.background,
    );
  }
}

class LanguageTile extends StatelessWidget {
  const LanguageTile({super.key, required this.option, required this.selected, required this.onTap});

  final LanguageOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: selected ? c.accent : c.border, width: selected ? 2 : 1),
        boxShadow: selected
            ? [BoxShadow(color: c.accent.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 6))]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? c.accent : c.surfaceMuted,
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: Text(
                    option.locale.languageCode.toUpperCase(),
                    style: context.text.titleMedium?.copyWith(
                      color: selected ? c.onAccent : c.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(option.native, style: context.text.titleMedium),
                      const SizedBox(height: 2),
                      Text(option.hint, style: context.text.bodySmall),
                    ],
                  ),
                ),
                AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: Icon(Icons.check_circle_rounded, color: c.accent, size: 26),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
