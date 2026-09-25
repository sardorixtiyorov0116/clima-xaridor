import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/catalog_providers.dart';
import '../../catalog/ui/widgets.dart';
import '../data/service_models.dart';
import '../services_providers.dart';

/// Xizmat narxi matni: qat'iy — summa, "…dan", yoki "Narxi kelishiladi".
String servicePriceText(BuildContext context, ServiceOffer o, {ServiceVariant? variant}) {
  final s = S.of(context);
  if (o.isQuote) return s.serviceByQuote;
  final p = variant?.price ?? o.fromPrice;
  if (p == null) return s.serviceByQuote;
  final many = variant == null && o.variants.where((v) => v.price != null).length > 1;
  return o.isFrom || many ? s.serviceFrom(sumText(context, p)) : sumText(context, p);
}

/// Hudud nomi: "Toshkent shahri · Yunusobod tumani".
String areaName(List<Region> regions, ServiceArea a, String lang) {
  final r = regions.where((x) => x.code == a.region).firstOrNull;
  if (r == null) return a.region;
  final d = r.districts.where((x) => x.code == a.district).firstOrNull;
  return d == null ? r.name.of(lang) : '${r.name.of(lang)} · ${d.name.of(lang)}';
}

/// Hudud tanlash: avval viloyat, keyin tuman. [requireDistrict] — buyurtmada
/// tumani bor viloyatda tuman majburiy.
Future<ServiceArea?> pickServiceArea(BuildContext context, {bool requireDistrict = false, ServiceArea? initial}) =>
    showModalBottomSheet<ServiceArea>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AreaSheet(requireDistrict: requireDistrict, initial: initial),
    );

class _AreaSheet extends ConsumerStatefulWidget {
  const _AreaSheet({required this.requireDistrict, this.initial});
  final bool requireDistrict;
  final ServiceArea? initial;

  @override
  ConsumerState<_AreaSheet> createState() => _AreaSheetState();
}

class _AreaSheetState extends ConsumerState<_AreaSheet> {
  Region? _region;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final lang = ref.watch(langProvider);
    final regions = ref.watch(regionsProvider);
    final h = MediaQuery.sizeOf(context).height * 0.75;

    return SizedBox(
      height: h,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.sm),
            child: Row(
              children: [
                if (_region != null)
                  IconButton(onPressed: () => setState(() => _region = null), icon: const Icon(Icons.arrow_back_rounded)),
                Expanded(
                  child: Text(_region?.name.of(lang) ?? s.serviceAreaPick, style: context.text.titleLarge),
                ),
              ],
            ),
          ),
          Expanded(
            child: regions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: ErrorRetry(error: e, onRetry: () => ref.invalidate(regionsProvider))),
              data: (list) {
                final r = _region;
                if (r == null) {
                  return ListView(
                    children: [
                      for (final x in list)
                        ListTile(
                          title: Text(x.name.of(lang)),
                          trailing: x.districts.isEmpty ? null : Icon(Icons.chevron_right_rounded, color: c.textTertiary),
                          selected: widget.initial?.region == x.code,
                          onTap: () {
                            if (x.districts.isEmpty) {
                              Navigator.pop(context, ServiceArea(region: x.code));
                            } else {
                              setState(() => _region = x);
                            }
                          },
                        ),
                    ],
                  );
                }
                return ListView(
                  children: [
                    if (!widget.requireDistrict)
                      ListTile(
                        leading: const Icon(Icons.public_rounded),
                        title: Text(s.serviceAreaWhole),
                        onTap: () => Navigator.pop(context, ServiceArea(region: r.code)),
                      ),
                    for (final d in r.districts)
                      ListTile(
                        title: Text(d.name.of(lang)),
                        selected: widget.initial?.district == d.code,
                        onTap: () => Navigator.pop(context, ServiceArea(region: r.code, district: d.code)),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Xizmat kartochkasi — ro'yxatlarda.
class ServiceCard extends ConsumerWidget {
  const ServiceCard({super.key, required this.offer});
  final ServiceOffer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final c = context.colors;
    final lang = ref.watch(langProvider);
    final o = offer;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = o.provider;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(Radii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: () => context.push('/service/${o.id}'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: c.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.md),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: o.photos.isNotEmpty
                      ? NetImage(o.photos.first, width: 300, fit: BoxFit.cover)
                      : ColoredBox(
                          color: Brand.mist.withValues(alpha: dark ? 0.12 : 0.45),
                          child: Icon(serviceIcon(o.category?.key ?? ''), size: 34, color: dark ? Brand.sky : Brand.navy),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.name.of(lang), maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
                    if (p != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                          ),
                          if (p.rating != null && p.rating! > 0) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFE08A00)),
                            Text(p.rating!.toStringAsFixed(1), style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            servicePriceText(context, o),
                            style: context.text.titleMedium?.copyWith(color: dark ? Brand.sky : Brand.navy),
                          ),
                        ),
                        if (o.warrantyMonths > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: c.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_user_outlined, size: 13, color: c.success),
                                const SizedBox(width: 4),
                                Text(s.serviceWarranty(o.warrantyMonths),
                                    style: context.text.bodySmall?.copyWith(color: c.success, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bosh sahifadagi xizmat turlari qatori (o'rnatish, tozalash, ta'mir…).
class HomeServicesStrip extends ConsumerWidget {
  const HomeServicesStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final c = context.colors;
    final lang = ref.watch(langProvider);
    final cats = ref.watch(serviceCategoriesProvider).value;
    if (cats == null || cats.isEmpty) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xl, Space.sm, Space.sm),
          child: Row(
            children: [
              Expanded(child: Text(s.servicesHome, style: context.text.titleLarge)),
              TextButton(onPressed: () => context.push('/services'), child: Text(s.servicesAll)),
            ],
          ),
        ),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            itemCount: cats.length,
            separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
            itemBuilder: (_, i) {
              final cat = cats[i];
              return Material(
                color: c.surface,
                borderRadius: BorderRadius.circular(Radii.lg),
                child: InkWell(
                  borderRadius: BorderRadius.circular(Radii.lg),
                  onTap: () => context.push('/services?c=${cat.key}'),
                  child: Container(
                    width: 112,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Radii.lg),
                      border: Border.all(color: c.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Brand.mist.withValues(alpha: dark ? 0.15 : 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(cat.icon, size: 19, color: dark ? Brand.sky : Brand.navy),
                        ),
                        Text(cat.name.of(lang),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodyMedium?.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600, height: 1.15)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
