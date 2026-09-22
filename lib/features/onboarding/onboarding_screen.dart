import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/buttons.dart';
import '../../l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  double _pos = 0;

  @override
  void initState() {
    super.initState();
    _page.addListener(() => setState(() => _pos = _page.page ?? 0));
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(storageProvider).setOnboarded();
    if (mounted) context.go('/auth/phone?first=1');
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final slides = [
      _Slide(icon: Icons.factory_outlined, badges: const [Icons.air_rounded, Icons.ac_unit_rounded],
          title: s.onb1Title, body: s.onb1Body),
      _Slide(icon: Icons.request_quote_outlined, badges: const [Icons.picture_as_pdf_outlined, Icons.shopping_cart_outlined],
          title: s.onb2Title, body: s.onb2Body),
      _Slide(icon: Icons.local_shipping_outlined, badges: const [Icons.location_on_outlined, Icons.schedule_rounded],
          title: s.onb3Title, body: s.onb3Body),
    ];
    final last = _pos.round() == slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, Space.sm, Space.sm, 0),
                child: AnimatedOpacity(
                  opacity: last ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: last ? null : _finish,
                    child: Text(s.onbSkip, style: context.text.titleMedium?.copyWith(color: c.textSecondary)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: slides.length,
                itemBuilder: (_, i) => _SlideView(slide: slides[i], offset: _pos - i),
              ),
            ),
            _Dots(count: slides.length, position: _pos),
            const SizedBox(height: Space.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              child: PrimaryButton(
                label: last ? s.onbStart : s.onbNext,
                icon: last ? null : Icons.arrow_forward_rounded,
                onPressed: () {
                  if (last) {
                    _finish();
                  } else {
                    _page.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
                  }
                },
              ),
            ),
            const SizedBox(height: Space.lg),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({required this.icon, required this.badges, required this.title, required this.body});
  final IconData icon;
  final List<IconData> badges;
  final String title;
  final String body;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.offset});

  final _Slide slide;

  /// -1..1 — sahifa qanchalik surilgan (parallaks uchun).
  final double offset;

  @override
  Widget build(BuildContext context) {
    final o = offset.clamp(-1.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      child: Column(
        children: [
          const Spacer(),
          Transform.translate(
            offset: Offset(o * -60, 0),
            child: Opacity(opacity: (1 - o.abs()).clamp(0.0, 1.0), child: _Illustration(slide: slide)),
          ),
          const Spacer(),
          Text(slide.title, textAlign: TextAlign.center, style: context.text.headlineMedium),
          const SizedBox(height: Space.md),
          Text(slide.body, textAlign: TextAlign.center, style: context.text.bodyLarge?.copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: Space.xl),
        ],
      ),
    );
  }
}

/// Rasm o'rniga brend ranglarida kompozitsiya — og'irlik qo'shmaydi, har ekranda tiniq.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 280,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                Brand.sky.withValues(alpha: dark ? 0.22 : 0.35),
                Brand.mist.withValues(alpha: 0.0),
              ]),
            ),
          ),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(44),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A3A73), Brand.navy],
              ),
              boxShadow: [
                BoxShadow(color: Brand.navy.withValues(alpha: 0.35), blurRadius: 40, offset: const Offset(0, 18)),
              ],
            ),
            child: Icon(slide.icon, size: 72, color: Colors.white),
          ),
          Positioned(top: 24, right: 30, child: _Badge(icon: slide.badges[0])),
          Positioned(bottom: 26, left: 26, child: _Badge(icon: slide.badges[1], accent: true)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, this.accent = false});
  final IconData icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: accent ? Brand.sky : c.surface,
        border: accent ? null : Border.all(color: c.border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Icon(icon,
          color: accent
              ? Brand.navy
              : (Theme.of(context).brightness == Brightness.dark ? Brand.sky : Brand.link),
          size: 28),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.position});
  final int count;
  final double position;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final t = (1 - (position - i).abs()).clamp(0.0, 1.0);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8 + 18 * t,
          height: 8,
          decoration: BoxDecoration(
            color: Color.lerp(c.border, c.accent, t),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
