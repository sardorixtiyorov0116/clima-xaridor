import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/catalog_providers.dart';
import '../../catalog/ui/widgets.dart';
import '../services_providers.dart';
import 'service_widgets.dart';

/// Xizmatlar katalogi: hudud, tur va hamkorlar takliflari.
class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key, this.category});
  final String? category;

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  late String? _cat = widget.category;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final lang = ref.watch(langProvider);
    final cats = ref.watch(serviceCategoriesProvider).value ?? const [];
    final area = ref.watch(serviceAreaProvider);
    final regions = ref.watch(regionsProvider).value ?? const [];
    final list = ref.watch(servicesProvider(_cat));

    return Scaffold(
      appBar: AppBar(title: Text(s.servicesTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(servicesProvider(_cat).future).catchError((_) => const <Never>[]),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xs, Space.gutter, Space.md),
                child: Material(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(Radii.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Radii.md),
                    onTap: () async {
                      final a = await pickServiceArea(context, initial: area);
                      if (a != null) ref.read(serviceAreaProvider.notifier).set(a);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Radii.md),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: c.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.serviceArea, style: context.text.bodySmall),
                                Text(areaName(regions, area, lang),
                                    style: context.text.bodyMedium?.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          Icon(Icons.expand_more_rounded, color: c.textTertiary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                  children: [
                    _CatChip(label: s.servicesAll, selected: _cat == null, onTap: () => setState(() => _cat = null)),
                    for (final x in cats)
                      _CatChip(
                        label: x.name.of(lang),
                        icon: x.icon,
                        selected: _cat == x.key,
                        onTap: () => setState(() => _cat = x.key),
                      ),
                  ],
                ),
              ),
            ),
            ...list.when(
              loading: () => [
                SliverPadding(
                  padding: const EdgeInsets.all(Space.gutter),
                  sliver: SliverList.separated(
                    itemCount: 4,
                    separatorBuilder: (_, _) => const SizedBox(height: Space.md),
                    itemBuilder: (_, _) => const Skeleton(height: 110, radius: Radii.lg),
                  ),
                ),
              ],
              error: (e, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: ErrorRetry(error: e, onRetry: () => ref.invalidate(servicesProvider(_cat)))),
                ),
              ],
              data: (items) => items.isEmpty
                  ? [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.all(Space.xxl),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home_repair_service_outlined, size: 56, color: c.textTertiary),
                              const SizedBox(height: Space.lg),
                              Text(s.servicesEmpty, style: context.text.titleLarge, textAlign: TextAlign.center),
                              const SizedBox(height: Space.sm),
                              Text(s.servicesEmptyBody, style: context.text.bodyMedium, textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                    ]
                  : [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.xxl),
                        sliver: SliverList.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: Space.md),
                          itemBuilder: (_, i) => ServiceCard(offer: items[i]),
                        ),
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: Space.sm),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        avatar: icon == null ? null : Icon(icon, size: 17, color: selected ? c.onAccent : c.textSecondary),
        showCheckmark: false,
        label: Text(label),
        labelStyle: context.text.bodyMedium?.copyWith(
          color: selected ? c.onAccent : c.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        selectedColor: c.accent,
        backgroundColor: c.surface,
        side: BorderSide(color: selected ? c.accent : c.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
    );
  }
}
