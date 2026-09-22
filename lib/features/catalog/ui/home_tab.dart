import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/brand.dart';
import '../../../l10n/app_localizations.dart';
import '../catalog_providers.dart';
import '../data/models.dart';
import 'widgets.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(productsProvider);
    ref.invalidate(bannersProvider);
    ref.invalidate(usdRateProvider);
    ref.invalidate(categoriesProvider);
    await ref.read(productsProvider.future).catchError((_) => <Product>[]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final products = ref.watch(productsProvider);
    final bannersAsync = ref.watch(bannersProvider);
    final banners = bannersAsync.value ?? const [];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        edgeOffset: 120,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            const _Header(),
            if (banners.isNotEmpty)
              SliverToBoxAdapter(child: _BannerCarousel(banners: banners))
            else if (bannersAsync.isLoading)
              const SliverToBoxAdapter(child: _BannerSkeleton()),
            const SliverToBoxAdapter(child: _CategoryStrip()),
            ...products.when(
              loading: () => [
                _title(context, s.homeNew),
                const SliverToBoxAdapter(child: _HorizontalSkeleton()),
                _title(context, s.homePopular),
                const ProductGridSkeleton(),
              ],
              error: (e, _) => [
                SliverToBoxAdapter(child: ErrorRetry(error: e, onRetry: () => _refresh(ref))),
              ],
              data: (all) {
                final sale = all.where((p) => p.onSale).toList();
                final fresh = [...all]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                final popular = [...all]..sort((a, b) {
                    // Narxli mahsulotlar oldinda — xaridor darhol narxni ko'radi.
                    final byPrice = (b.hasPrice ? 1 : 0) - (a.hasPrice ? 1 : 0);
                    return byPrice != 0 ? byPrice : b.views.compareTo(a.views);
                  });
                return [
                  if (sale.isNotEmpty) ...[
                    _title(context, s.homeSale),
                    SliverToBoxAdapter(child: _HorizontalProducts(products: sale.take(10).toList())),
                  ],
                  _title(context, s.homeNew),
                  SliverToBoxAdapter(child: _HorizontalProducts(products: fresh.take(10).toList())),
                  _title(context, s.homePopular),
                  ProductGrid(products: popular),
                ];
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
          ],
        ),
      ),
    );
  }

  static Widget _title(BuildContext context, String text) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xl, Space.gutter, Space.md),
          child: Text(text, style: context.text.titleLarge),
        ),
      );
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = S.of(context);
    final favCount = ref.watch(favoritesProvider).length;
    return SliverAppBar(
      pinned: true,
      floating: false,
      toolbarHeight: 60,
      collapsedHeight: 60,
      expandedHeight: 124,
      backgroundColor: c.background,
      titleSpacing: Space.gutter,
      title: const BrandLockup(height: 28),
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: () => context.push('/favorites'),
          icon: Badge(
            isLabelVisible: favCount > 0,
            label: Text('$favCount'),
            child: const Icon(Icons.favorite_border_rounded),
          ),
        ),
        const SizedBox(width: Space.sm),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 10),
          child: Material(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.md),
              onTap: () => context.push('/search'),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: c.textTertiary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.searchHint,
                          style: context.text.bodyLarge?.copyWith(color: c.textTertiary),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerCarousel extends ConsumerStatefulWidget {
  const _BannerCarousel({required this.banners});
  final List<PromoBanner> banners;

  @override
  ConsumerState<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<_BannerCarousel> {
  final _page = PageController(viewportFraction: 0.9);
  Timer? _auto;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      _auto = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_page.hasClients) return;
        final next = (_index + 1) % widget.banners.length;
        _page.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
      });
    }
  }

  @override
  void dispose() {
    _auto?.cancel();
    _page.dispose();
    super.dispose();
  }

  void _open(PromoBanner b) {
    if (b.productId != null) {
      context.push('/product/${b.productId}');
    } else if (b.link != null) {
      launchUrl(Uri.parse(b.link!), mode: LaunchMode.inAppBrowserView);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
    final c = context.colors;
    return Column(
      children: [
        const SizedBox(height: Space.sm),
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _page,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              final b = widget.banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Material(
                  borderRadius: BorderRadius.circular(Radii.lg),
                  clipBehavior: Clip.antiAlias,
                  color: Brand.navy,
                  child: InkWell(
                    onTap: () => _open(b),
                    // Banner rasmlari kvadrat yoki 1.6:1 — o'ngda to'liq kvadrat panel, chapda matn.
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.sm, Space.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.title.of(lang),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.titleLarge?.copyWith(color: Colors.white, height: 1.2)),
                                if (b.text.of(lang).isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(b.text.of(lang),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.bodyMedium
                                          ?.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                                ],
                                const Spacer(),
                                if (b.productId != null || b.link != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Brand.sky,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(S.of(context).bannerMore,
                                            style: context.text.bodySmall
                                                ?.copyWith(color: Brand.navy, fontWeight: FontWeight.w800)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_forward_rounded, size: 14, color: Brand.navy),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        AspectRatio(
                          aspectRatio: 1,
                          child: NetImage(b.image, width: 700, fit: BoxFit.cover),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: Space.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.banners.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index ? c.accent : c.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Ildiz kategoriyalar — gorizontal belgilar qatori.
class _CategoryStrip extends ConsumerWidget {
  const _CategoryStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final lang = ref.watch(langProvider);
    final cats = ref.watch(categoriesProvider).value;
    final products = ref.watch(productsProvider).value;
    if (cats == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.lg, 0, 0),
        child: SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, _) => const SizedBox(width: Space.md),
            itemBuilder: (_, _) => const Column(children: [
              Skeleton(width: 60, height: 60, radius: 18),
              SizedBox(height: 8),
              Skeleton(width: 56, height: 10),
            ]),
          ),
        ),
      );
    }
    // Faqat mahsuloti bor ildiz kategoriyalar.
    final roots = cats.where((cat) {
      if (cat.parentId != null) return false;
      if (products == null) return true;
      final ids = categoryWithChildren(cats, cat.id);
      return products.any((p) => ids.contains(p.categoryId));
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(top: Space.lg),
      child: SizedBox(
        height: 104,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          itemCount: roots.length,
          separatorBuilder: (_, _) => const SizedBox(width: Space.md),
          itemBuilder: (_, i) {
            final cat = roots[i];
            return SizedBox(
              width: 76,
              child: InkWell(
                borderRadius: BorderRadius.circular(Radii.md),
                onTap: () => context.push('/category/${cat.id}'),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: c.border),
                      ),
                      child: Icon(categoryIcon(cat.id), color: Theme.of(context).brightness == Brightness.dark ? Brand.sky : Brand.link, size: 28),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat.name.of(lang),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(color: c.textSecondary, height: 1.2, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HorizontalProducts extends StatelessWidget {
  const _HorizontalProducts({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 334,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.lg),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => SizedBox(width: 164, child: ProductCard(product: products[i])),
      ),
    );
  }
}

/// Banner skeleti — haqiqiy karusel shaklida: markazda karta, yonlarida qo'shnilari, ostida nuqtalar.
class _BannerSkeleton extends StatelessWidget {
  const _BannerSkeleton();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final card = w * 0.9 - 10;
    return Column(
      children: [
        const SizedBox(height: Space.sm),
        SizedBox(
          height: 168,
          child: OverflowBox(
            maxWidth: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Skeleton(width: card, height: 168, radius: Radii.lg),
                const SizedBox(width: 10),
                Skeleton(width: card, height: 168, radius: Radii.lg),
                const SizedBox(width: 10),
                Skeleton(width: card, height: 168, radius: Radii.lg),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.md),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Skeleton(width: 6, height: 6, radius: 3),
            SizedBox(width: 6),
            Skeleton(width: 18, height: 6, radius: 3),
            SizedBox(width: 6),
            Skeleton(width: 6, height: 6, radius: 3),
          ],
        ),
      ],
    );
  }
}

class _HorizontalSkeleton extends StatelessWidget {
  const _HorizontalSkeleton();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 334,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, _) => const SizedBox(width: 164, child: ProductCardSkeleton()),
        ),
      );
}
