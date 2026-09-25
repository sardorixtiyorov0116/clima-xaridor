import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/buttons.dart';
import '../../../l10n/app_localizations.dart';
import '../cart_resolved.dart';
import '../catalog_providers.dart';
import '../data/models.dart';
import 'product_screen.dart';
import 'widgets.dart';

class CartTab extends ConsumerWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final c = context.colors;
    final lines = ref.watch(cartProvider);
    final products = ref.watch(productsProvider);
    final rate = ref.watch(usdRateProvider).value;
    final lang = ref.watch(langProvider);

    if (lines.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(s.tabCart)),
        body: _EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: s.cartEmptyTitle,
          body: s.cartEmptyBody,
          action: s.goToCatalog,
          onAction: () => context.go('/catalog'),
        ),
      );
    }

    final all = products.value ?? const <Product>[];
    final resolved = ref.watch(resolvedCartProvider);
    final priced = resolved.where((r) => r.price != null);
    final unpriced = resolved.length - priced.length;
    // So'mdagi narx backenddan tayyor keladi (№37); kurs faqat eski javoblar uchun zaxira.
    final sums = [for (final r in priced) (r.price!.effectiveSum(rate), r.line.qty)];
    final total = sums.any((x) => x.$1 == null) ? null : sums.fold<int>(0, (a, x) => a + x.$1! * x.$2);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.tabCart),
        actions: [
          TextButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(s.cartClearConfirm, style: ctx.text.titleLarge),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: ctx.colors.danger),
                      child: Text(s.clear),
                    ),
                  ],
                ),
              );
              if (ok == true) ref.read(cartProvider.notifier).clear();
            },
            child: Text(s.clear, style: TextStyle(color: c.textSecondary)),
          ),
        ],
      ),
      body: products.isLoading && all.isEmpty
          ? ListView.separated(
              padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, Space.lg),
              itemCount: lines.length.clamp(1, 6),
              separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
              itemBuilder: (_, _) => const Skeleton(height: 132, radius: Radii.lg),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, Space.lg),
              itemCount: resolved.length,
              separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
              itemBuilder: (_, i) {
                final r = resolved[i];
                return Material(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(Radii.lg),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Radii.lg),
                    onTap: () => context.push('/product/${r.product.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F6FA),
                              borderRadius: BorderRadius.circular(Radii.md),
                            ),
                            child: NetImage(r.product.cover, width: 240),
                          ),
                          const SizedBox(width: Space.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.product.name.of(lang),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.bodyMedium?.copyWith(color: c.textPrimary)),
                                if (r.subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(r.subtitle!, style: context.text.bodySmall),
                                ],
                                const SizedBox(height: 6),
                                PriceView.of(r.price),
                                const SizedBox(height: Space.sm),
                                QtyStepper(
                                  compact: true,
                                  qty: r.line.qty,
                                  onChanged: (q) => ref.read(cartProvider.notifier).setQty(r.line.key, q),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: _CheckoutBar(total: total, unpriced: unpriced),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.total, required this.unpriced});
  final int? total;
  final int unpriced;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.md),
      decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(s.cartTotal, style: context.text.bodyMedium)),
                // Hammasi narxsiz bo'lsa "0 so'm" emas — narxni sotuvchi berishini aytamiz.
                if (total != null && total! > 0)
                  Text(sumText(context, total!), style: context.text.titleLarge)
                else if (unpriced > 0)
                  Text(s.kpUnpricedCell, style: context.text.titleMedium?.copyWith(color: c.textSecondary)),
              ],
            ),
            if (unpriced > 0 && total != null && total! > 0) ...[
              const SizedBox(height: 2),
              Text(s.cartUnpriced(unpriced), style: context.text.bodySmall),
            ],
            const SizedBox(height: Space.md),
            if (unpriced == 0) ...[
              PrimaryButton(label: s.checkoutOrder, onPressed: () => context.push('/checkout?kind=order')),
              const SizedBox(height: Space.sm),
              OutlinedButton(
                onPressed: () => context.push('/checkout?kind=quote'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: c.textPrimary,
                  side: BorderSide(color: c.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
                ),
                child: Text(s.checkoutQuote, style: context.text.titleMedium),
              ),
            ] else
              PrimaryButton(label: s.checkoutQuote, onPressed: () => context.push('/checkout?kind=quote')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.body, required this.action, required this.onAction});
  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(color: Brand.mist.withValues(alpha: 0.35), shape: BoxShape.circle),
              child: Icon(icon, size: 46, color: Theme.of(context).brightness == Brightness.dark ? Brand.sky : Brand.navy),
            ),
            const SizedBox(height: Space.xl),
            Text(title, textAlign: TextAlign.center, style: context.text.titleLarge),
            const SizedBox(height: Space.sm),
            Text(body, textAlign: TextAlign.center, style: context.text.bodyMedium),
            const SizedBox(height: Space.xl),
            SizedBox(width: 220, child: PrimaryButton(label: action, onPressed: onAction)),
            const SizedBox(height: Space.xxl),
          ],
        ),
      ),
    );
  }
}

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final ids = ref.watch(favoritesProvider);
    final async = ref.watch(productsProvider);
    final products = async.value ?? const <Product>[];
    final list = products.where((p) => ids.contains(p.id)).toList();
    return Scaffold(
      appBar: AppBar(title: Text(s.favoritesTitle)),
      body: async.isLoading && products.isEmpty && ids.isNotEmpty
          ? CustomScrollView(slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: Space.sm)),
              ProductGridSkeleton(count: ids.length.clamp(2, 6)),
            ])
          : list.isEmpty
          ? _EmptyState(
              icon: Icons.favorite_border_rounded,
              title: s.favoritesEmptyTitle,
              body: s.favoritesEmptyBody,
              action: s.goToCatalog,
              onAction: () => context.go('/catalog'),
            )
          : CustomScrollView(slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: Space.sm)),
              ProductGrid(products: list),
              const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
            ]),
    );
  }
}
