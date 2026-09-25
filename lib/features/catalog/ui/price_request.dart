import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../l10n/app_localizations.dart';
import '../catalog_providers.dart';
import '../data/models.dart';
import 'widgets.dart';

/// Narxsiz mahsulotda "Narxini bilish" — bosiladigan tugmacha.
/// Bosilganda: KP olish (asosiy) yoki sotuvchiga ilovada yozish.
class PriceRequestChip extends ConsumerWidget {
  const PriceRequestChip({super.key, required this.product, this.model, this.variant, this.big = false});
  final Product product;

  /// Mahsulot sahifasida tanlangan model va variant (kartochkada — yo'q).
  final ProductModel? model;
  final Variant? variant;
  final bool big;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Brand.sky : Brand.link;
    return Material(
      color: fg.withValues(alpha: dark ? 0.14 : 0.08),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () {
          HapticFeedback.selectionClick();
          showPriceRequestSheet(context, product: product, model: model, variant: variant, onProductPage: big);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: big ? 14 : 10, vertical: big ? 8 : 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sell_outlined, size: big ? 18 : 15, color: fg),
              SizedBox(width: big ? 6 : 4),
              Flexible(
                child: Text(
                  s.priceOnRequest,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (big ? context.text.titleMedium : context.text.bodySmall)
                      ?.copyWith(color: fg, fontWeight: FontWeight.w700),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: big ? 20 : 16, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showPriceRequestSheet(BuildContext context,
    {required Product product, ProductModel? model, Variant? variant, bool onProductPage = false}) {
  // Router context oyna ochilishidan oldin olinadi — oyna o'zi hech bir sahifaga tegishli emas.
  final router = GoRouter.of(context);
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true, // pastki menyu ustida, butun ekran bo'ylab
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => _PriceRequestSheet(
        product: product, model: model, variant: variant, router: router, onProductPage: onProductPage),
  );
}

class _PriceRequestSheet extends ConsumerWidget {
  const _PriceRequestSheet({
    required this.product,
    required this.router,
    required this.onProductPage,
    this.model,
    this.variant,
  });
  final Product product;
  final ProductModel? model;
  final Variant? variant;
  final GoRouter router;
  final bool onProductPage;

  /// Savatga qo'shib, savatga o'tadi — u yerda "KP olish".
  /// Model yoki variant tanlanmagan bo'lsa — mahsulot sahifasida tanlashni so'raymiz.
  void _getQuote(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final p = product;
    final m = model ?? (p.models.length == 1 ? p.models.first : null);
    final v = variant ?? (m != null && m.variants.length == 1 ? m.variants.first : null);
    final needModel = p.models.length > 1 && m == null;
    final needVariant = !needModel && m != null && m.variants.length > 1 && v == null;
    if (needModel || needVariant) {
      // Ogohlantirish oyna yopilishidan oldin — keyin bu kontekst yo'q bo'ladi.
      if (onProductPage) {
        showSnack(context, needModel ? s.chooseModelFirst : s.chooseVariantFirst, icon: Icons.layers_outlined);
      }
      Navigator.pop(context);
      if (!onProductPage) router.push('/product/${p.id}');
      return;
    }
    Navigator.pop(context);
    final key = cartKey(p.id, m?.id, v?.id);
    if (!ref.read(cartProvider).any((l) => l.key == key)) {
      ref.read(cartProvider.notifier).add(p.id, m?.id,
          variantId: v?.id, label: v != null ? (v.code.isNotEmpty ? v.code : v.name) : m?.title);
    }
    router.go('/cart');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final c = context.colors;
    final lang = ref.watch(langProvider);
    final store = product.store;
    final title = [product.name.of(lang), variant?.name ?? model?.title].whereType<String>().where((e) => e.isNotEmpty).join(' · ');
    ButtonStyle outlined() => OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: c.textPrimary,
          side: BorderSide(color: c.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
          textStyle: context.text.titleMedium,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE3F3FE), Color(0xFFF7FBFF)],
                  ),
                ),
                child: NetImage(product.cover, width: 160),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.priceOnRequest, style: context.text.titleLarge),
                    const SizedBox(height: 2),
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Text(s.priceSheetBody, style: context.text.bodyMedium),
          const SizedBox(height: Space.lg),
          PrimaryButton(
            label: s.priceSheetQuote,
            icon: Icons.request_quote_outlined,
            onPressed: () => _getQuote(context, ref),
          ),
          if (store != null) ...[
            const SizedBox(height: Space.sm),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                router.push('/chat/store/${store.id}?product=${product.id}', extra: store);
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: Text(s.chatWriteToStore),
              style: outlined(),
            ),
          ],
        ],
      ),
    );
  }
}
