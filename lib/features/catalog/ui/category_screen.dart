import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../catalog_providers.dart';
import '../data/models.dart';
import 'widgets.dart';

enum SortMode { popular, cheap, expensive, fresh }

/// Saralash va "faqat narxlilar" — kategoriya, qidiruv va sevimlilarda bir xil.
List<Product> applySort(List<Product> list, SortMode mode, {bool pricedOnly = false}) {
  final out = pricedOnly ? list.where((p) => p.hasPrice).toList() : [...list];
  int byPrice(Product a, Product b, int dir) {
    // Narxsizlar har doim oxirida.
    if (!a.hasPrice && !b.hasPrice) return b.views.compareTo(a.views);
    if (!a.hasPrice) return 1;
    if (!b.hasPrice) return -1;
    final pa = a.minSaleUsd ?? a.minUsd!;
    final pb = b.minSaleUsd ?? b.minUsd!;
    return dir * pa.compareTo(pb);
  }

  switch (mode) {
    case SortMode.popular:
      out.sort((a, b) => b.views.compareTo(a.views));
    case SortMode.cheap:
      out.sort((a, b) => byPrice(a, b, 1));
    case SortMode.expensive:
      out.sort((a, b) => byPrice(a, b, -1));
    case SortMode.fresh:
      out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  return out;
}

String sortLabel(S s, SortMode m) => switch (m) {
      SortMode.popular => s.sortPopular,
      SortMode.cheap => s.sortCheap,
      SortMode.expensive => s.sortExpensive,
      SortMode.fresh => s.sortNew,
    };

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key, required this.categoryId});
  final int categoryId;

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  SortMode _sort = SortMode.popular;
  bool _pricedOnly = false;
  int? _sub;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lang = ref.watch(langProvider);
    final cats = ref.watch(categoriesProvider).value ?? const <Category>[];
    final products = ref.watch(productsProvider);
    final cat = cats.where((x) => x.id == widget.categoryId).firstOrNull;
    final subs = cats.where((x) => x.parentId == widget.categoryId).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(cat?.name.of(lang) ?? s.tabCatalog),
          ),
          SliverToBoxAdapter(
            child: _Filters(
              subs: subs,
              lang: lang,
              selectedSub: _sub,
              onSub: (v) => setState(() => _sub = v),
              sort: _sort,
              onSort: (v) => setState(() => _sort = v),
              pricedOnly: _pricedOnly,
              onPricedOnly: (v) => setState(() => _pricedOnly = v),
            ),
          ),
          ...products.when(
            loading: () => [const ProductGridSkeleton()],
            error: (e, _) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: ErrorRetry(error: e, onRetry: () => ref.invalidate(productsProvider))),
              ),
            ],
            data: (all) {
              final ids = categoryWithChildren(cats, _sub ?? widget.categoryId);
              final list = applySort(all.where((p) => ids.contains(p.categoryId)).toList(), _sort,
                  pricedOnly: _pricedOnly);
              if (list.isEmpty) {
                return [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Empty(text: s.emptyCategory),
                  ),
                ];
              }
              return [ProductGrid(products: list)];
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.subs,
    required this.lang,
    required this.selectedSub,
    required this.onSub,
    required this.sort,
    required this.onSort,
    required this.pricedOnly,
    required this.onPricedOnly,
  });

  final List<Category> subs;
  final String lang;
  final int? selectedSub;
  final ValueChanged<int?> onSub;
  final SortMode sort;
  final ValueChanged<SortMode> onSort;
  final bool pricedOnly;
  final ValueChanged<bool> onPricedOnly;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subs.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                children: [
                  AppChip(label: s.allItems, selected: selectedSub == null, onTap: () => onSub(null)),
                  for (final c in subs)
                    AppChip(label: c.name.of(lang), selected: selectedSub == c.id, onTap: () => onSub(c.id)),
                ],
              ),
            ),
          const SizedBox(height: Space.sm),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
              children: [
                AppChip(
                  label: sortLabel(s, sort),
                  icon: Icons.swap_vert_rounded,
                  selected: false,
                  trailingIcon: Icons.expand_more_rounded,
                  onTap: () async {
                    final v = await showSortSheet(context, sort);
                    if (v != null) onSort(v);
                  },
                ),
                AppChip(
                  label: s.pricedOnly,
                  icon: pricedOnly ? Icons.check_rounded : null,
                  selected: pricedOnly,
                  onTap: () => onPricedOnly(!pricedOnly),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<SortMode?> showSortSheet(BuildContext context, SortMode current) {
  final s = S.of(context);
  return showModalBottomSheet<SortMode>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.sm),
            child: Text(s.sortTitle, style: ctx.text.headlineSmall),
          ),
          for (final m in SortMode.values)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              title: Text(sortLabel(s, m), style: ctx.text.titleMedium),
              trailing: m == current ? Icon(Icons.check_rounded, color: ctx.colors.accent) : null,
              onTap: () => Navigator.pop(ctx, m),
            ),
          const SizedBox(height: Space.md),
        ],
      ),
    ),
  );
}

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.trailingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.onAccent : c.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(right: Space.sm),
      child: Material(
        color: selected ? c.accent : c.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? c.accent : c.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 6)],
                Text(label, style: context.text.bodyMedium?.copyWith(color: fg, fontWeight: FontWeight.w600)),
                if (trailingIcon != null) ...[const SizedBox(width: 2), Icon(trailingIcon, size: 18, color: fg)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(Space.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: c.textTertiary),
          const SizedBox(height: Space.lg),
          Text(text, textAlign: TextAlign.center, style: context.text.bodyMedium),
        ],
      ),
    );
  }
}
