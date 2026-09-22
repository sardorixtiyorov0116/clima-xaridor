import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../l10n/app_localizations.dart';
import '../catalog_providers.dart';
import '../data/models.dart';
import 'price_request.dart';
import 'widgets.dart';

class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key, required this.productId});
  final int productId;

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  int? _modelId;
  int? _variantId;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(productDetailProvider(widget.productId));
    // Ro'yxatdagi qisqa ma'lumot — sahifa darhol chiziladi, to'liq ma'lumot kelguncha.
    final brief = ref
        .watch(productsProvider)
        .value
        ?.where((p) => p.id == widget.productId)
        .firstOrNull;
    final p = detail.value ?? brief;

    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: detail.hasError
            ? Center(
                child: ErrorRetry(
                    error: detail.error!,
                    onRetry: () => ref.invalidate(productDetailProvider(widget.productId))))
            : const _PageSkeleton(),
      );
    }

    final model = p.models.where((m) => m.id == _modelId).firstOrNull ??
        (p.models.length == 1 ? p.models.first : null);
    final variant = model?.variants.where((v) => v.id == _variantId).firstOrNull ??
        (model != null && model.variants.length == 1 ? model.variants.first : null);
    final s = S.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _Gallery(product: p),
          SliverToBoxAdapter(
            child: _Info(product: p, model: model, variant: variant, loading: !detail.hasValue),
          ),
          if (p.models.length > 6)
            SliverToBoxAdapter(
              child: _SelectField(
                label: s.modelLabel,
                placeholder: s.chooseModel,
                value: model?.title,
                // Modelda variantlar bo'lsa narx faqat variantlarda ko'rinadi.
                trailing: model == null || model.variants.length > 1
                    ? null
                    : PriceView(usd: model.fromPrice?.usd, saleUsd: model.fromPrice?.saleUsd),
                onTap: () async {
                  final id = await _pickOption(context, title: s.chooseModel, selected: model?.id, options: [
                    for (final m in p.models)
                      _Option(
                        id: m.id,
                        title: m.title,
                        subtitle: m.variants.length > 1 ? S.of(context).variantsCount(m.variants.length) : null,
                        price: m.variants.length > 1 ? null : (m.price ?? m.fromPrice),
                        hidePrice: m.variants.length > 1,
                      ),
                  ]);
                  if (id != null && mounted) {
                    setState(() {
                      _modelId = id;
                      _variantId = null;
                    });
                  }
                },
              ),
            )
          else if (p.models.length > 1)
            SliverToBoxAdapter(
              child: _Models(
                product: p,
                selected: model?.id,
                onSelect: (id) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _modelId = id == _modelId ? null : id;
                    _variantId = null;
                  });
                },
              ),
            ),
          if (model != null && model.variants.length > 1)
            SliverToBoxAdapter(
              child: _SelectField(
                label: s.variantsTitle,
                placeholder: s.chooseVariant,
                value: variant == null ? null : (variant.name.isNotEmpty ? variant.name : variant.code),
                trailing: variant == null ? null : PriceView(usd: variant.price?.usd, saleUsd: variant.price?.saleUsd),
                onTap: () async {
                  final id = await _pickOption(context, title: s.chooseVariant, selected: variant?.id, options: [
                    for (final v in model.variants)
                      _Option(
                        id: v.id,
                        title: v.name.isNotEmpty ? v.name : v.code,
                        subtitle: v.name.isNotEmpty && v.code != v.name ? v.code : null,
                        price: v.price,
                      ),
                  ]);
                  if (id != null && mounted) setState(() => _variantId = id);
                },
              ),
            ),
          // To'liq ma'lumot kelguncha bo'limlar o'rnida skelet — sahifa sakramaydi.
          if (!detail.hasValue && !detail.hasError)
            const SliverToBoxAdapter(child: _SectionsSkeleton())
          else
            SliverToBoxAdapter(child: _Specs(product: p, model: model, detailLoaded: detail.hasValue)),
          if (p.sizesUrl != null)
            SliverToBoxAdapter(child: _HtmlSection(title: s.sizesTitle, url: p.sizesUrl!)),
          if (p.markingUrl != null)
            SliverToBoxAdapter(child: _HtmlSection(title: s.markingTitle, url: p.markingUrl!)),
          if (p.descriptionUrl != null)
            SliverToBoxAdapter(child: _HtmlSection(title: s.descriptionTitle, url: p.descriptionUrl!)),
          if (p.purposeUrl != null)
            SliverToBoxAdapter(child: _HtmlSection(title: s.purposeTitle, url: p.purposeUrl!)),
          if (p.store != null) SliverToBoxAdapter(child: _StoreCard(store: p.store!)),
          const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
        ],
      ),
      bottomNavigationBar: _BuyBar(product: p, model: model, variant: variant),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.product});
  final Product product;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final images = widget.product.images;
    final top = MediaQuery.paddingOf(context).top;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 380,
      backgroundColor: c.background,
      leading: const Padding(padding: EdgeInsets.all(6), child: _RoundIcon(icon: Icons.arrow_back_rounded)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: FavoriteButton(productId: widget.product.id, size: 22),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          // Kartochkadagidek moviy-oq gradient — oq fondagi rasmlar ajralib turadi.
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE3F3FE), Color(0xFFF7FBFF)],
            ),
          ),
          padding: EdgeInsets.only(top: top + 40, bottom: 28),
          child: Stack(
            children: [
              PageView.builder(
                itemCount: images.isEmpty ? 1 : images.length,
                onPageChanged: (i) => setState(() => _i = i),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: images.isEmpty ? null : () => _openViewer(context, images, i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: NetImage(images.isEmpty ? null : images[i], width: 900),
                  ),
                ),
              ),
              if (images.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var k = 0; k < images.length; k++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: k == _i ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: k == _i ? Brand.navy : const Color(0xFFC9D2DE),
                            borderRadius: BorderRadius.circular(3),
                          ),
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

  void _openViewer(BuildContext context, List<String> images, int start) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: const Color(0xFFF4F6FA),
      pageBuilder: (_, _, _) => _Viewer(images: images, start: start),
      transitionsBuilder: (_, a, _, w) => FadeTransition(opacity: a, child: w),
    ));
  }
}

class _Viewer extends StatelessWidget {
  const _Viewer({required this.images, required this.start});
  final List<String> images;
  final int start;

  @override
  Widget build(BuildContext context) {
    // Mahsulot rasmlari shaffof PNG — qora fonda ko'rinmay qoladi, shuning uchun och fon.
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FA),
        foregroundColor: const Color(0xFF0B1B33),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: start),
        itemCount: images.length,
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 4,
          child: Center(child: NetImage(images[i], width: 1400)),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).maybePop(),
        child: Icon(icon, color: c.textPrimary, size: 22),
      ),
    );
  }
}

class _Info extends ConsumerWidget {
  const _Info({required this.product, required this.model, required this.variant, this.loading = false});
  final Product product;
  final ProductModel? model;
  final Variant? variant;

  /// To'liq ma'lumot hali kelmagan — qisqa tavsif o'rnida skelet.
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final c = context.colors;
    final lang = ref.watch(langProvider);
    final p = product;
    final m = model;
    final multiVariant = m != null && m.variants.length > 1 && variant == null;
    final Price? price = variant != null ? (variant!.price ?? m?.price) : m?.fromPrice;
    final hasPrice = m != null ? price != null : p.hasPrice;
    final short = p.shortDescription?.of(lang) ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasPrice) ...[
            PriceRequestChip(product: p, model: m, variant: variant, big: true),
            const SizedBox(height: 8),
            Text(s.priceOnRequestHint, style: context.text.bodyMedium),
          ] else if (m != null)
            PriceView(usd: price?.usd, saleUsd: price?.saleUsd, big: true, from: multiVariant)
          else
            PriceView(usd: p.minUsd, saleUsd: p.minSaleUsd, from: p.multiModel, big: true),
          const SizedBox(height: Space.md),
          Text(p.name.of(lang), style: context.text.headlineSmall?.copyWith(fontSize: 21)),
          // Qisqa tavsif kelguncha skelet; kelganda balandlik silliq o'zgaradi (sakramaydi).
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: short.isNotEmpty
                  ? Padding(
                      key: const ValueKey('d'),
                      padding: const EdgeInsets.only(top: Space.sm),
                      child: Text(short, style: context.text.bodyMedium),
                    )
                  : loading
                      ? const Padding(
                          key: ValueKey('s'),
                          padding: EdgeInsets.only(top: Space.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Skeleton(height: 12),
                              SizedBox(height: 9),
                              Skeleton(height: 12),
                              SizedBox(height: 9),
                              Skeleton(height: 12),
                              SizedBox(height: 9),
                              Skeleton(width: 200, height: 12),
                            ],
                          ),
                        )
                      : const SizedBox(key: ValueKey('e'), width: double.infinity),
            ),
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              if (p.store != null) _Meta(leading: StoreLogo(store: p.store!, size: 18), text: p.store!.name),
              if (p.producer != null && p.producer != p.store?.name)
                _Meta(icon: Icons.factory_outlined, text: p.producer!),
              if (p.models.length > 1) _Meta(icon: Icons.layers_outlined, text: s.modelsCount(p.models.length)),
            ],
          ),
          Divider(height: Space.xxl, color: c.border),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({this.icon, this.leading, required this.text});
  final IconData? icon;
  final Widget? leading;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading ?? Icon(icon, size: 16, color: c.textSecondary),
          const SizedBox(width: 6),
          Text(text, style: context.text.bodySmall?.copyWith(color: c.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Models extends ConsumerWidget {
  const _Models({required this.product, required this.selected, required this.onSelect});
  final Product product;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final c = context.colors;
    final rate = ref.watch(usdRateProvider).value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(selected == null ? s.chooseModel : s.modelLabel, style: context.text.titleMedium),
          const SizedBox(height: Space.md),
          // Hamma tugmacha bir xil o'lchamda: nomi + ikkinchi qator (narx, variantlar soni yoki "Narxini bilish").
          LayoutBuilder(builder: (context, box) {
            final w = (box.maxWidth - Space.sm) / 2;
            return Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final m in product.models)
                  SizedBox(
                    width: w,
                    child: _ModelChip(
                      title: m.title,
                      sub: m.variants.length > 1
                          ? s.variantsCount(m.variants.length)
                          : (m.fromPrice == null
                              ? s.priceOnRequest
                              : (rate == null ? '…' : sumText(context, rate.toSum(m.fromPrice!.effective)))),
                      subMuted: m.variants.length > 1 || m.fromPrice == null,
                      selected: m.id == selected,
                      onTap: () => onSelect(m.id),
                      c: c,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _ModelChip extends StatelessWidget {
  const _ModelChip({
    required this.title,
    required this.sub,
    required this.subMuted,
    required this.selected,
    required this.onTap,
    required this.c,
  });
  final String title;
  final String sub;
  final bool subMuted;
  final bool selected;
  final VoidCallback onTap;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 62,
      decoration: BoxDecoration(
        color: selected ? c.accent.withValues(alpha: 0.06) : c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: selected ? c.accent : c.border, width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    fontSize: 12.5,
                    color: subMuted ? c.textTertiary : c.textPrimary,
                    fontWeight: subMuted ? FontWeight.w500 : FontWeight.w700,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mahsulot hali umuman noma'lum (to'g'ridan-to'g'ri havola) — butun sahifa skeleti.
class _PageSkeleton extends StatelessWidget {
  const _PageSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: const [
          SizedBox(height: 320, child: Skeleton(radius: 0)),
          Padding(
            padding: EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.gutter, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 170, height: 24),
                SizedBox(height: 14),
                Skeleton(height: 20),
                SizedBox(height: 8),
                Skeleton(width: 220, height: 20),
                SizedBox(height: 16),
                Skeleton(height: 12),
                SizedBox(height: 9),
                Skeleton(height: 12),
                SizedBox(height: 9),
                Skeleton(width: 200, height: 12),
                SizedBox(height: 24),
              ],
            ),
          ),
          _SectionsSkeleton(),
        ],
      );
}

/// Bo'limlar yuklanayotganda — yopiq bo'lim shaklidagi skeletlar.
class _SectionsSkeleton extends StatelessWidget {
  const _SectionsSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, 0),
        child: Column(
          children: [
            for (var i = 0; i < 3; i++) ...[
              const Skeleton(height: 54, radius: Radii.lg),
              const SizedBox(height: Space.md),
            ],
          ],
        ),
      );
}

/// Xarakteristikalar: tanlangan modelning texnik jadvali + havo sarfi va bosim. Standart yopiq.
class _Specs extends ConsumerWidget {
  const _Specs({required this.product, required this.model, required this.detailLoaded});
  final Product product;
  final ProductModel? model;
  final bool detailLoaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final m = model;
    if (product.models.isEmpty) return const SizedBox.shrink();
    final facts = <(String, String)>[
      if (m?.airflow != null) (s.specAirflow, '${groupDigits(m!.airflow!.round())} m³/h'),
      if (m?.pressure != null) (s.specPressure, '${groupDigits(m!.pressure!.round())} Pa'),
    ];
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Bo'lim doim turadi; tanlangan modelda na jadval, na ko'rsatkich bo'lsa — ichida bo'sh holat.
    var empty = false;
    if (m != null && facts.isEmpty) {
      if (m.specsUrl == null) {
        empty = detailLoaded;
      } else {
        final html = ref.watch(htmlProvider(m.specsUrl!));
        empty = html.hasError || (html.hasValue && html.value == null);
      }
    }
    return _Expandable(
      title: s.specsTitle,
      trailing: m?.title,
      child: m == null
          ? Text(s.specsChooseModel, style: context.text.bodyMedium)
          : empty
          ? const _NoSpecs()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (facts.isNotEmpty) ...[
                  Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.sm,
                    children: [
                      for (final f in facts)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Brand.mist.withValues(alpha: dark ? 0.12 : 0.4),
                            borderRadius: BorderRadius.circular(Radii.sm),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.$1, style: context.text.bodySmall),
                              Text(f.$2, style: context.text.titleMedium),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.md),
                ],
                if (m.specsUrl != null)
                  _HtmlBody(url: m.specsUrl!)
                else if (!detailLoaded)
                  const LinearProgressIndicator()
              ],
            ),
    );
  }
}

/// Bitta qatorli tanlash maydoni: bosilganda pastdan ro'yxat ochiladi.
/// Model va variantlar ko'p bo'lsa sahifa cho'zilib ketmaydi.
class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.placeholder,
    required this.value,
    required this.trailing,
    required this.onTap,
  });
  final String label;
  final String placeholder;
  final String? value;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final empty = value == null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.titleMedium),
          const SizedBox(height: Space.sm),
          Material(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.md),
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(color: empty ? c.accent : c.border, width: empty ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value ?? placeholder,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyLarge?.copyWith(
                          color: empty ? c.textSecondary : c.textPrimary,
                          fontWeight: empty ? FontWeight.w500 : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                    const SizedBox(width: 4),
                    Icon(Icons.unfold_more_rounded, color: c.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Option {
  const _Option({
    required this.id,
    required this.title,
    this.subtitle,
    this.price,
    this.hidePrice = false,
  });
  final int id;
  final String title;
  final String? subtitle;
  final Price? price;

  /// Narx ustuni umuman ko'rsatilmaydi (variantli model).
  final bool hidePrice;
}

/// Pastdan ochiladigan ro'yxat; 8 tadan ko'p bo'lsa — qidiruv bilan.
Future<int?> _pickOption(BuildContext context, {required String title, required List<_Option> options, int? selected}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _OptionSheet(title: title, options: options, selected: selected),
  );
}

class _OptionSheet extends StatefulWidget {
  const _OptionSheet({required this.title, required this.options, required this.selected});
  final String title;
  final List<_Option> options;
  final int? selected;

  @override
  State<_OptionSheet> createState() => _OptionSheetState();
}

class _OptionSheetState extends State<_OptionSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final q = _q.toLowerCase();
    final list = q.isEmpty
        ? widget.options
        : widget.options
            .where((o) => o.title.toLowerCase().contains(q) || (o.subtitle ?? '').toLowerCase().contains(q))
            .toList();
    final maxH = MediaQuery.sizeOf(context).height * 0.8;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.md),
              child: Text(widget.title, style: context.text.headlineSmall),
            ),
            if (widget.options.length > 8)
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.sm),
                child: TextField(
                  onChanged: (v) => setState(() => _q = v.trim()),
                  decoration: InputDecoration(
                    hintText: s.searchInList,
                    isDense: true,
                    prefixIcon: Icon(Icons.search_rounded, color: c.textTertiary),
                  ),
                ),
              ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: Space.lg),
                itemCount: list.length,
                separatorBuilder: (_, _) => Divider(color: c.border, indent: Space.gutter, endIndent: Space.gutter),
                itemBuilder: (_, i) {
                  final o = list[i];
                  final sel = o.id == widget.selected;
                  return InkWell(
                    onTap: () => Navigator.pop(context, o.id),
                    child: Container(
                      color: sel ? c.accent.withValues(alpha: 0.06) : null,
                      padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(o.title,
                                    style: context.text.bodyLarge?.copyWith(
                                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                                if (o.subtitle != null && o.subtitle!.isNotEmpty)
                                  Text(o.subtitle!, style: context.text.bodySmall),
                              ],
                            ),
                          ),
                          if (!o.hidePrice) ...[
                            const SizedBox(width: 8),
                            PriceView(usd: o.price?.usd, saleUsd: o.price?.saleUsd),
                          ],
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 22,
                            child: sel ? Icon(Icons.check_rounded, color: c.accent) : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yig'iladigan bo'lim (tavsif, xarakteristikalar, o'lchamlar) — standart yopiq.
class _Expandable extends StatefulWidget {
  const _Expandable({required this.title, required this.child, this.trailing});
  final String title;
  final String? trailing;
  final Widget child;

  @override
  State<_Expandable> createState() => _ExpandableState();
}

class _ExpandableState extends State<_Expandable> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.md),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(Radii.lg),
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                child: Row(
                  children: [
                    Expanded(child: Text(widget.title, style: context.text.titleMedium)),
                    if (widget.trailing != null)
                      Text(widget.trailing!, style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more_rounded, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _open ? widget.child : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yig'iladigan HTML bo'lim — matni bo'sh bo'lsa umuman ko'rsatilmaydi.
class _HtmlSection extends ConsumerWidget {
  const _HtmlSection({required this.title, required this.url});
  final String title;
  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final html = ref.watch(htmlProvider(url));
    if (html.hasError || (html.hasValue && html.value == null)) return const SizedBox.shrink();
    return _Expandable(title: title, child: _HtmlBody(url: url));
  }
}

/// Xarakteristika yo'q — belgi va qisqa izoh.
class _NoSpecs extends StatelessWidget {
  const _NoSpecs();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.surfaceMuted, shape: BoxShape.circle),
            child: Icon(Icons.inventory_2_outlined, size: 20, color: c.textTertiary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(S.of(context).specsEmpty, style: context.text.bodyMedium)),
        ],
      ),
    );
  }
}

/// HTML matn yoki jadval. Keng jadval (4+ ustun) gorizontal suriladi.
class _HtmlBody extends ConsumerWidget {
  const _HtmlBody({required this.url});
  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final html = ref.watch(htmlProvider(url));
    return html.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const SizedBox.shrink(),
      data: (body) {
        if (body == null) return const SizedBox.shrink();
        final border = '1px solid ${_hex(c.border)}';
        final cols = _columns(body);
        // Muharrir `<colgroup>` ga "min-width: 25px" yozadi — jadval shunga siqiladi.
        final clean = body
            .replaceAll(RegExp(r'<colgroup>.*?</colgroup>', dotAll: true), '')
            .replaceAll(RegExp(r'<table[^>]*>'), '<table>');
        final view = HtmlWidget(
          clean,
          textStyle: context.text.bodyMedium?.copyWith(color: c.textPrimary, fontSize: 13.5),
          customStylesBuilder: (e) => switch (e.localName) {
            'td' => {'border': border, 'padding': '6px 8px', 'vertical-align': 'middle'},
            'th' => {
                'border': border,
                'padding': '6px 8px',
                'background-color': _hex(c.surfaceMuted),
                'vertical-align': 'middle',
              },
            'table' => {'border-collapse': 'collapse', 'width': '100%'},
            'p' => {'margin': '0'},
            _ => null,
          },
        );
        if (cols <= 3) return view;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: cols * 110.0, child: view),
        );
      },
    );
  }

  static String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  /// Jadvaldagi ustunlar soni (`<col>` bo'yicha).
  static int _columns(String html) {
    final cols = RegExp(r'<col[\s>]').allMatches(html).length;
    final tables = RegExp(r'<table').allMatches(html).length;
    if (cols > 0 && tables > 0) return (cols / tables).ceil();
    return 0;
  }
}

class _StoreCard extends ConsumerWidget {
  const _StoreCard({required this.store});
  final Store store;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final c = context.colors;
    final lang = ref.watch(langProvider);
    final about = store.description?.of(lang) ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, 0),
      child: Container(
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.sellerTitle, style: context.text.bodySmall),
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: store.logoUrl == null
                      ? Icon(Icons.storefront_outlined, color: c.textTertiary)
                      : Padding(padding: const EdgeInsets.all(4), child: NetImage(store.logoUrl, width: 160)),
                ),
                const SizedBox(width: Space.md),
                Expanded(child: Text(store.name, style: context.text.titleLarge)),
              ],
            ),
            if (about.isNotEmpty) ...[
              const SizedBox(height: Space.md),
              Text(about, maxLines: 3, overflow: TextOverflow.ellipsis, style: context.text.bodyMedium),
            ],
            const SizedBox(height: Space.lg),
            Row(
              children: [
                if (store.phone != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          launchUrl(Uri.parse('tel:${store.phone!.replaceAll(RegExp(r'[^\d+]'), '')}')),
                      icon: const Icon(Icons.call_outlined, size: 18),
                      label: Text(s.callSeller),
                      style: _outlined(c),
                    ),
                  ),
                if (store.phone != null && store.telegram != null) const SizedBox(width: Space.sm),
                if (store.telegram != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => launchUrl(
                          Uri.parse('https://t.me/${store.telegram!.replaceAll('@', '')}'),
                          mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.send_outlined, size: 18),
                      label: const Text('Telegram'),
                      style: _outlined(c),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static ButtonStyle _outlined(AppColors c) => OutlinedButton.styleFrom(
        foregroundColor: c.textPrimary,
        side: BorderSide(color: c.border),
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      );
}

/// Pastki panel: narx + "Savatga". Bir nechta model bo'lsa — avval model tanlanadi.
class _BuyBar extends ConsumerWidget {
  const _BuyBar({required this.product, required this.model, required this.variant});
  final Product product;
  final ProductModel? model;
  final Variant? variant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final c = context.colors;
    final needModel = product.models.length > 1 && model == null;
    final needVariant = !needModel && model != null && model!.variants.length > 1 && variant == null;
    final key = cartKey(product.id, model?.id, variant?.id);
    final inCart = ref.watch(cartProvider).where((l) => l.key == key).firstOrNull;

    return Container(
      padding: EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.md + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: inCart == null
          ? PrimaryButton(
              label: needModel ? s.chooseModel : (needVariant ? s.chooseVariant : s.addToCart),
              icon: needModel || needVariant ? null : Icons.add_shopping_cart_rounded,
              onPressed: needModel || needVariant
                  ? () => showSnack(context, needModel ? s.chooseModelFirst : s.chooseVariantFirst,
                      icon: Icons.layers_outlined)
                  : () {
                      final label = variant != null
                          ? (variant!.code.isNotEmpty ? variant!.code : variant!.name)
                          : model?.title;
                      ref.read(cartProvider.notifier).add(product.id, model?.id, variantId: variant?.id, label: label);
                      showSnack(context, s.addedToCart, icon: Icons.check_circle_outline_rounded);
                    },
            )
          : Row(
              children: [
                QtyStepper(
                  qty: inCart.qty,
                  onChanged: (q) => ref.read(cartProvider.notifier).setQty(key, q),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: PrimaryButton(label: s.goToCart, onPressed: () => context.go('/cart')),
                ),
              ],
            ),
    );
  }
}

class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.qty, required this.onChanged, this.compact = false});
  final int qty;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final h = compact ? 36.0 : 56.0;
    Widget btn(IconData icon, VoidCallback onTap) => InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(width: h, height: h, child: Icon(icon, size: compact ? 18 : 22, color: c.textPrimary)),
        );
    return Container(
      height: h,
      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(Radii.md)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(qty <= 1 ? Icons.delete_outline_rounded : Icons.remove_rounded, () => onChanged(qty - 1)),
          SizedBox(
            width: compact ? 26 : 34,
            child: Text('$qty',
                textAlign: TextAlign.center,
                style: (compact ? context.text.bodyLarge : context.text.titleMedium)
                    ?.copyWith(fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()])),
          ),
          btn(Icons.add_rounded, () => onChanged(qty + 1)),
        ],
      ),
    );
  }
}
