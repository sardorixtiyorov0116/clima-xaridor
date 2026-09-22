import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/feedback.dart';
import '../../../l10n/app_localizations.dart';
import '../catalog_providers.dart';
import '../data/models.dart';
import 'price_request.dart';

/// `36229145` → `36 229 145` (tor bo'shliq bilan — qatorga bo'linmaydi).
String groupDigits(int v) {
  final s = v.abs().toString();
  final b = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}

String sumText(BuildContext context, int sum) => S.of(context).priceSum(groupDigits(sum));

/// Cloudinary rasmiga o'lcham qo'shadi — ro'yxatda 1000px o'rniga ~500px yuklanadi.
String imageUrl(String url, {int width = 500}) {
  var u = url;
  if (u.contains('res.cloudinary.com') && u.contains('/upload/')) {
    u = u.replaceFirst('/upload/', '/upload/w_$width,c_limit,q_auto,f_auto/');
  }
  // Ba'zi manzillarda kirill harflari kodlanmagan, ba'zilarida esa buzuq "%" bor —
  // ikkalasida ham yiqilmasdan to'g'ri manzil qaytaramiz.
  try {
    return Uri.encodeFull(Uri.decodeFull(u));
  } catch (_) {
    return u.replaceAllMapped(RegExp(r'[^\x00-\x7F]'), (m) => Uri.encodeComponent(m[0]!));
  }
}

class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.width = 500, this.fit = BoxFit.contain});
  final String? url;
  final int width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final placeholder = Center(child: Icon(Icons.image_outlined, color: c.textTertiary, size: 32));
    if (url == null) return placeholder;
    return CachedNetworkImage(
      imageUrl: imageUrl(url!, width: width),
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, _) => const Skeleton(),
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

/// Narx: aksiya bo'lsa eski narx ustidan chizilgan; narx yo'q bo'lsa "Narxini bilish".
class PriceView extends ConsumerWidget {
  const PriceView({super.key, required this.usd, this.saleUsd, this.from = false, this.big = false});
  final double? usd;
  final double? saleUsd;
  final bool from;
  final bool big;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final c = context.colors;
    final rate = ref.watch(usdRateProvider).value;
    final style = (big ? context.text.headlineSmall : context.text.titleMedium)
        ?.copyWith(fontWeight: FontWeight.w800, height: 1.15);
    if (usd == null) {
      return Text(s.priceOnRequest,
          style: (big ? context.text.titleLarge : context.text.bodyMedium)
              ?.copyWith(color: c.textSecondary, fontWeight: FontWeight.w600));
    }
    if (rate == null) {
      return Container(
        width: big ? 160 : 90,
        height: big ? 24 : 16,
        decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(6)),
      );
    }
    final onSale = saleUsd != null && saleUsd! < usd!;
    final main = rate.toSum(onSale ? saleUsd! : usd!);
    final text = sumText(context, main);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onSale)
          Text(sumText(context, rate.toSum(usd!)),
              style: context.text.bodySmall?.copyWith(decoration: TextDecoration.lineThrough)),
        Text(
          from ? s.priceFrom(text) : text,
          style: style?.copyWith(color: onSale ? c.danger : c.textPrimary),
        ),
      ],
    );
  }
}

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.productId, this.size = 20, this.filledBg = true});
  final int productId;
  final double size;
  final bool filledBg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final fav = ref.watch(favoritesProvider).contains(productId);
    return Material(
      color: filledBg ? c.surface.withValues(alpha: 0.92) : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          ref.read(favoritesProvider.notifier).toggle(productId);
        },
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
            child: Icon(
              fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(fav),
              size: size,
              color: fav ? c.danger : c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final lang = ref.watch(langProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = product;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: dark ? Border.all(color: c.border) : null,
        boxShadow: dark
            ? null
            : [
                BoxShadow(color: Brand.navy.withValues(alpha: 0.07), blurRadius: 18, offset: const Offset(0, 6)),
              ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(Radii.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/product/${p.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.08,
                child: Stack(
                  children: [
                    // Mahsulot rasmlari oq fonda — moviy-oq gradient ularni ajratib ko'rsatadi.
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFE3F3FE), Color(0xFFF7FBFF)],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(padding: const EdgeInsets.all(14), child: NetImage(p.cover, width: 400)),
                    ),
                    Positioned(top: 6, right: 6, child: FavoriteButton(productId: p.id)),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Row(children: [
                        if (p.onSale) _Tag(text: S.of(context).saleTag, color: c.danger),
                        if (p.multiModel) ...[
                          if (p.onSale) const SizedBox(width: 4),
                          _Tag(text: S.of(context).modelsCount(p.models.length), color: Brand.navy.withValues(alpha: 0.85)),
                        ],
                      ]),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name.of(lang),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium?.copyWith(color: c.textPrimary, height: 1.28),
                      ),
                      const Spacer(),
                      if (p.store != null) ...[
                        StoreBadge(store: p.store!),
                        const SizedBox(height: 6),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: p.hasPrice
                                ? FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.bottomLeft,
                                    child: PriceView(usd: p.minUsd, saleUsd: p.minSaleUsd, from: p.multiModel),
                                  )
                                // Narxsiz: bosiladigan "Narxini bilish" — KP, qo'ng'iroq, Telegram.
                                : Align(alignment: Alignment.centerLeft, child: PriceRequestChip(product: p)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CardCartButton(product: p),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartochka pastidagi tugma:
/// - tanlov shart bo'lmasa: «Savatga» → qo'shilgach − son + boshqaruvi;
/// - model/variant tanlash kerak bo'lsa: «Tanlash» (savatda bo'lsa — «Savatda · N») → mahsulot sahifasi.
class CardCartButton extends ConsumerWidget {
  const CardCartButton({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final c = context.colors;
    final p = product;
    final lines = ref.watch(cartProvider).where((l) => l.productId == p.id).toList();
    final inCartQty = lines.fold<int>(0, (a, l) => a + l.qty);
    const h = 36.0;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));

    if (!p.quickAddable) {
      return SizedBox(
        height: h,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => context.push('/product/${p.id}'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: inCartQty > 0 ? c.success : c.textPrimary,
            side: BorderSide(color: inCartQty > 0 ? c.success : c.border),
            shape: shape,
          ),
          child: Text(inCartQty > 0 ? s.inCartCount(inCartQty) : s.chooseOptions,
              style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: inCartQty > 0 ? c.success : c.textPrimary)),
        ),
      );
    }

    final model = p.models.length == 1 ? p.models.first : null;
    final variant = model != null && model.variants.length == 1 ? model.variants.first : null;
    final key = cartKey(p.id, model?.id, variant?.id);
    final line = lines.where((l) => l.key == key).firstOrNull;

    if (line == null) {
      return SizedBox(
        height: h,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            ref.read(cartProvider.notifier).add(p.id, model?.id,
                variantId: variant?.id, label: variant?.code.isNotEmpty == true ? variant!.code : model?.title);
          },
          icon: const Icon(Icons.add_shopping_cart_rounded, size: 17),
          label: Text(s.addToCart),
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: c.accent,
            foregroundColor: c.onAccent,
            textStyle: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            shape: shape,
          ),
        ),
      );
    }

    Widget btn(IconData icon, VoidCallback onTap) => Material(
          color: c.accent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: SizedBox(width: h, height: h, child: Icon(icon, size: 18, color: c.onAccent)),
          ),
        );
    return Container(
      height: h,
      decoration: BoxDecoration(color: c.accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          btn(line.qty <= 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
              () => ref.read(cartProvider.notifier).setQty(key, line.qty - 1)),
          Expanded(
            child: Text('${line.qty}',
                textAlign: TextAlign.center,
                style: context.text.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          ),
          btn(Icons.add_rounded, () => ref.read(cartProvider.notifier).setQty(key, line.qty + 1)),
        ],
      ),
    );
  }
}

/// Do'kon logosi + nomi (kartochka va mahsulot sahifasi uchun).
class StoreBadge extends StatelessWidget {
  const StoreBadge({super.key, required this.store, this.size = 18});
  final Store store;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        StoreLogo(store: store, size: size),
        const SizedBox(width: 6),
        Expanded(
          child: Text(store.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(color: c.textSecondary, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class StoreLogo extends StatelessWidget {
  const StoreLogo({super.key, required this.store, this.size = 18});
  final Store store;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: c.border),
      ),
      child: store.logoUrl == null
          ? Icon(Icons.storefront_outlined, size: size * 0.7, color: c.textTertiary)
          : Padding(padding: EdgeInsets.all(size * 0.08), child: NetImage(store.logoUrl, width: (size * 4).round())),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Text(text,
            style: context.text.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
      );
}

/// 2 ustunli mahsulotlar panjarasi (sliver).
class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Space.lg),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 334,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, i) => ProductCard(product: products[i]),
          childCount: products.length,
        ),
      ),
    );
  }
}

/// Yuklanayotgan panjara — kartochka shaklidagi skelet, yumshoq miltillash bilan.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key, this.count = 6});
  final int count;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Space.lg),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 334,
        ),
        delegate: SliverChildBuilderDelegate((_, _) => const ProductCardSkeleton(), childCount: count),
      ),
    );
  }
}

/// Kartochka shaklidagi skelet (rasm, 2 qator nom, do'kon, narx, tugma).
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.lg)),
      clipBehavior: Clip.antiAlias,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(aspectRatio: 1.08, child: Skeleton(radius: 0)),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 12, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(height: 12),
                SizedBox(height: 6),
                Skeleton(width: 100, height: 12),
                SizedBox(height: 16),
                Skeleton(width: 80, height: 10),
                SizedBox(height: 10),
                Skeleton(width: 110, height: 16),
                SizedBox(height: 10),
                Skeleton(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Yuklanayotgan joy — "nafas oladigan" kulrang blok (rasm, matn, karta o'rnida).
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.width, this.height, this.radius = 10});
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) => Pulse(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: context.colors.surfaceMuted,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      );
}

/// Skelet uchun yumshoq "nafas olish" animatsiyasi.
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child});
  final Widget child;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: Tween(begin: 0.55, end: 1.0).animate(_c), child: widget.child);
}

/// Yuklab bo'lmadi — sabab va "Qayta urinish".
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(Space.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: c.textTertiary),
          const SizedBox(height: Space.lg),
          Text(errorText(context, error), textAlign: TextAlign.center, style: context.text.bodyMedium),
          const SizedBox(height: Space.lg),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(S.of(context).retry),
          ),
        ],
      ),
    );
  }
}

/// Kategoriya belgisi — id bo'yicha (bazadagi ildiz kategoriyalar).
IconData categoryIcon(int id) => switch (id) {
      1 || 2 || 3 || 4 || 5 || 33 => Icons.ac_unit_rounded,
      6 => Icons.kitchen_outlined,
      7 => Icons.local_fire_department_outlined,
      8 => Icons.sync_alt_rounded,
      9 || 10 || 11 || 12 => Icons.hvac_rounded,
      13 || 14 || 15 || 16 || 17 || 18 || 19 || 20 => Icons.air_rounded,
      21 => Icons.cyclone_rounded,
      22 || 23 || 24 || 25 => Icons.tune_rounded,
      26 => Icons.grid_on_rounded,
      27 || 28 || 29 => Icons.volume_off_outlined,
      30 => Icons.category_outlined,
      31 => Icons.filter_alt_outlined,
      32 => Icons.extension_outlined,
      34 => Icons.construction_rounded,
      _ => Icons.more_horiz_rounded,
    };
