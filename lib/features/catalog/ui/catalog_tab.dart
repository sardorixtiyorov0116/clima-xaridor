import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../catalog_providers.dart';
import '../data/models.dart';
import 'widgets.dart';

/// Katalog: ildiz kategoriyalar ro'yxati, har birida mahsulotlar soni.
class CatalogTab extends ConsumerWidget {
  const CatalogTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final c = context.colors;
    final lang = ref.watch(langProvider);
    final cats = ref.watch(categoriesProvider);
    final products = ref.watch(productsProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.tabCatalog),
        actions: [
          IconButton(onPressed: () => context.push('/search'), icon: const Icon(Icons.search_rounded)),
          const SizedBox(width: Space.xs),
        ],
      ),
      body: cats.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, Space.xxl),
          itemCount: 8,
          separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
          itemBuilder: (_, _) => const Skeleton(height: 76, radius: Radii.lg),
        ),
        error: (e, _) => Center(child: ErrorRetry(error: e, onRetry: () => ref.invalidate(categoriesProvider))),
        data: (all) {
          int count(Category cat) {
            if (products == null) return -1;
            final ids = categoryWithChildren(all, cat.id);
            return products.where((p) => ids.contains(p.categoryId)).length;
          }

          final roots = all.where((x) => x.parentId == null).map((x) => (x, count(x))).where((e) => e.$2 != 0).toList()
            ..sort((a, b) => b.$2.compareTo(a.$2));

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, Space.xxl),
            itemCount: roots.length,
            separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
            itemBuilder: (_, i) {
              final (cat, n) = roots[i];
              return Material(
                color: c.surface,
                borderRadius: BorderRadius.circular(Radii.lg),
                child: InkWell(
                  borderRadius: BorderRadius.circular(Radii.lg),
                  onTap: () => context.push('/category/${cat.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Brand.mist.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.12 : 0.45),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(categoryIcon(cat.id),
                              color: Theme.of(context).brightness == Brightness.dark ? Brand.sky : Brand.navy),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Text(cat.name.of(lang), style: context.text.titleMedium)),
                        if (n > 0)
                          Text('$n', style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, color: c.textTertiary),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
