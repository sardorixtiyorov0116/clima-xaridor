import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/buttons.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/catalog_providers.dart';
import '../../catalog/ui/widgets.dart';
import '../data/service_models.dart';
import '../services_providers.dart';
import 'service_widgets.dart';

/// Xizmat sahifasi: rasmlar, hamkor, variant va miqdor, tavsif.
class ServiceScreen extends ConsumerStatefulWidget {
  const ServiceScreen({super.key, required this.serviceId, this.variantId});
  final int serviceId;
  final int? variantId;

  @override
  ConsumerState<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends ConsumerState<ServiceScreen> {
  int? _variant;
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final lang = ref.watch(langProvider);
    final async = ref.watch(serviceDetailProvider(widget.serviceId));
    final dark = Theme.of(context).brightness == Brightness.dark;

    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: ListView(
          padding: const EdgeInsets.all(Space.gutter),
          children: const [
            Skeleton(height: 220, radius: Radii.lg),
            SizedBox(height: Space.lg),
            Skeleton(width: 220, height: 26),
            SizedBox(height: Space.md),
            Skeleton(height: 120, radius: Radii.lg),
          ],
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: ErrorRetry(error: e, onRetry: () => ref.invalidate(serviceDetailProvider(widget.serviceId)))),
      ),
      data: (o) {
        final variants = o.variants;
        _variant ??= widget.variantId ?? o.suggestedVariant?.id ?? (variants.isNotEmpty ? variants.first.id : null);
        final v = variants.where((x) => x.id == _variant).firstOrNull;
        final unitCount = o.unit == 'piece' || o.unit == 'm' || o.unit == 'm2';
        final total = v?.price == null ? null : v!.price! * _qty;
        final p = o.provider;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: o.photos.isEmpty ? 160 : 280,
                flexibleSpace: FlexibleSpaceBar(
                  background: o.photos.isEmpty
                      ? Container(
                          color: Brand.mist.withValues(alpha: dark ? 0.12 : 0.45),
                          alignment: Alignment.center,
                          child: Icon(serviceIcon(o.category?.key ?? ''), size: 64, color: dark ? Brand.sky : Brand.navy),
                        )
                      : PageView(
                          children: [for (final u in o.photos) NetImage(u, width: 1000, fit: BoxFit.cover)],
                        ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.gutter, Space.xxl),
                sliver: SliverList.list(
                  children: [
                    if (o.category != null)
                      Text(o.category!.name.of(lang), style: context.text.bodySmall?.copyWith(color: dark ? Brand.sky : Brand.link)),
                    const SizedBox(height: 4),
                    Text(o.name.of(lang), style: context.text.headlineSmall),
                    const SizedBox(height: Space.sm),
                    Text(servicePriceText(context, o, variant: v),
                        style: context.text.titleLarge?.copyWith(color: dark ? Brand.sky : Brand.navy)),
                    if (p != null) ...[
                      const SizedBox(height: Space.lg),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(Radii.md),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(
                          children: [
                            ClipOval(
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: p.logo != null
                                    ? NetImage(p.logo, width: 120)
                                    : ColoredBox(color: c.surfaceMuted, child: Icon(Icons.storefront_rounded, color: c.textSecondary)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, style: context.text.titleMedium),
                                  Text(
                                    [
                                      if (p.rating != null && p.rating! > 0) '★ ${p.rating!.toStringAsFixed(1)}',
                                      if (p.jobsDone > 0) s.serviceJobsDone(p.jobsDone),
                                    ].join(' · '),
                                    style: context.text.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: Space.md),
                    Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.sm,
                      children: [
                        if (o.warrantyMonths > 0) _Pill(icon: Icons.verified_user_outlined, text: s.serviceWarranty(o.warrantyMonths), color: c.success),
                        if (o.duration != null && o.duration! > 0) _Pill(icon: Icons.schedule_rounded, text: s.serviceDuration(o.duration!)),
                        if (o.visitFee != null) _Pill(icon: Icons.directions_car_outlined, text: s.serviceVisitFee(sumText(context, o.visitFee!))),
                      ],
                    ),
                    if (o.isFrom || o.isQuote) ...[
                      const SizedBox(height: Space.md),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Brand.mist.withValues(alpha: dark ? 0.12 : 0.4),
                          borderRadius: BorderRadius.circular(Radii.md),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: dark ? Brand.sky : Brand.navy, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(o.isQuote ? s.serviceQuoteNote : s.serviceFromNote,
                                  style: context.text.bodyMedium?.copyWith(color: c.textPrimary)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (variants.length > 1) ...[
                      const SizedBox(height: Space.xl),
                      Text(s.serviceChooseVariant, style: context.text.titleMedium),
                      const SizedBox(height: Space.sm),
                      for (final x in variants)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Space.sm),
                          child: _VariantTile(
                            title: x.name.of(lang),
                            price: x.price == null ? s.serviceByQuote : sumText(context, x.price!),
                            selected: x.id == _variant,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _variant = x.id);
                            },
                          ),
                        ),
                    ],
                    if (unitCount && !o.isQuote) ...[
                      const SizedBox(height: Space.md),
                      Row(
                        children: [
                          Expanded(child: Text(s.serviceQty, style: context.text.titleMedium)),
                          _Stepper(value: _qty, onChanged: (x) => setState(() => _qty = x)),
                        ],
                      ),
                    ],
                    if (o.description.of(lang).isNotEmpty) ...[
                      const SizedBox(height: Space.xl),
                      Text(s.serviceAbout, style: context.text.titleMedium),
                      const SizedBox(height: Space.sm),
                      Text(o.description.of(lang), style: context.text.bodyMedium?.copyWith(color: c.textPrimary, height: 1.45)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.md + MediaQuery.paddingOf(context).bottom),
            decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
            child: Row(
              children: [
                if (total != null) ...[
                  Text(o.isFrom ? s.serviceFrom(sumText(context, total)) : sumText(context, total),
                      style: context.text.titleLarge),
                  const SizedBox(width: Space.md),
                ],
                Expanded(
                  child: PrimaryButton(
                    label: o.isQuote ? s.serviceAskPrice : s.serviceOrder,
                    onPressed: _variant == null
                        ? null
                        : () => context.push('/service/${o.id}/book?v=$_variant&q=$_qty'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final col = color ?? c.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: col.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: col),
          const SizedBox(width: 6),
          Text(text, style: context.text.bodySmall?.copyWith(color: color ?? c.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _VariantTile extends StatelessWidget {
  const _VariantTile({required this.title, required this.price, required this.selected, required this.onTap});
  final String title;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: selected ? c.accent : c.border, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: selected ? c.accent : c.textTertiary, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: context.text.bodyMedium?.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600))),
              Text(price, style: context.text.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: c.border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: value > 1 ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove_rounded)),
          SizedBox(width: 28, child: Text('$value', textAlign: TextAlign.center, style: context.text.titleMedium)),
          IconButton(onPressed: value < 50 ? () => onChanged(value + 1) : null, icon: const Icon(Icons.add_rounded)),
        ],
      ),
    );
  }
}
