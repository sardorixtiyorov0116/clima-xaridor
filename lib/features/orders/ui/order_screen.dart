import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/catalog_providers.dart';
import '../../catalog/data/models.dart';
import '../../catalog/ui/widgets.dart';
import '../data/order_models.dart';
import '../orders_providers.dart';
import 'kp_pdf.dart';
import 'orders_tab.dart' show orderStatusLabel;
import 'tracking_view.dart';

String _date(DateTime? d) =>
    d == null ? '' : '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

/// Buyurtma sahifasi. KP bo'lsa — hujjat ko'rinishi, PDF, qabul qilish / rad etish.
class OrderScreen extends ConsumerStatefulWidget {
  const OrderScreen({super.key, required this.orderId, this.initial});
  final int orderId;

  /// Rasmiylashtirishdan to'g'ridan-to'g'ri kelganda — ro'yxat yuklanguncha shu ko'rsatiladi.
  final Order? initial;

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  bool _busy = false;
  bool _pdfBusy = false;

  @override
  void initState() {
    super.initState();
    // Ro'yxat ancha oldin yuklangan bo'lishi mumkin — sahifa ochilganda KP ning oxirgi holati olinadi.
    // Yangilanayotganda eski ma'lumot ko'rinib turadi, sahifa bo'shab qolmaydi.
    Future.microtask(() {
      if (mounted) ref.invalidate(myOrdersProvider);
    });
  }

  /// KP blanki uchun do'kon rekvizitlari. `/stores/all` da manzil, e-pochta va sayt bor;
  /// mahsulot ichidagi `store` qisqartirilgan, unda faqat nom, logo va telefon keladi.
  Store? _store(int storeId) {
    final full = ref.read(storesProvider).value ?? const <Store>[];
    final hit = full.where((s) => s.id == storeId).firstOrNull;
    if (hit != null) return hit;
    final all = ref.read(productsProvider).value ?? const <Product>[];
    return all.map((p) => p.store).whereType<Store>().where((s) => s.id == storeId).firstOrNull;
  }

  Future<void> _pdf(Order o, List<Quote> quotes) async {
    final s = S.of(context);
    setState(() => _pdfBusy = true);
    try {
      final bytes =
          await buildKpPdf(s: s, lang: ref.read(langProvider), order: o, quotes: quotes, storeOf: _store);
      // Bironta do'kon bo'limi tayyor emas — bo'sh hujjat o'rniga holatni aytamiz.
      if (bytes == null) {
        if (mounted) showSnack(context, s.kpPreparing, icon: Icons.hourglass_top_rounded);
        return;
      }
      await shareKpPdf(bytes, 'KP-${o.id}-v${quotes.first.version}.pdf');
    } catch (_) {
      if (mounted) showSnack(context, s.pdfFailed, icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  Future<void> _run(Future<void> Function() call, String okText) async {
    setState(() => _busy = true);
    try {
      await call();
      ref.invalidate(myOrdersProvider);
      if (mounted) showSnack(context, okText, icon: Icons.check_circle_outline_rounded);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, errorText(context, e), icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept(Order o, Quote q) async {
    final s = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.kpAcceptConfirmTitle, style: ctx.text.titleLarge),
        content: Text(s.kpAcceptConfirmBody(sumText(ctx, q.total.round())), style: ctx.text.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.kpAccept)),
        ],
      ),
    );
    if (ok != true) return;
    HapticFeedback.mediumImpact();
    await _run(
      () => ref.read(orderRepositoryProvider).acceptQuote(o.id, version: q.version, company: o.companyName, tin: o.companyTin),
      s.kpAccepted,
    );
  }

  Future<void> _reject(Order o) async {
    final s = S.of(context);
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.kpRejectTitle, style: ctx.text.titleLarge),
        content: TextField(
          controller: ctrl,
          maxLength: 500,
          maxLines: 3,
          decoration: InputDecoration(hintText: s.kpRejectHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ctx.colors.danger),
            child: Text(s.kpReject),
          ),
        ],
      ),
    );
    final reason = ctrl.text;
    ctrl.dispose();
    if (ok != true) return;
    await _run(() => ref.read(orderRepositoryProvider).rejectQuote(o.id, reason), s.kpRejected);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final orders = ref.watch(myOrdersProvider);
    ref.watch(storesProvider); // KP blanki rekvizitlari yuklansin
    final o = orders.value?.where((x) => x.id == widget.orderId).firstOrNull ?? widget.initial;

    if (o == null) {
      return Scaffold(
        appBar: AppBar(),
        body: orders.hasError
            ? Center(child: ErrorRetry(error: orders.error!, onRetry: () => ref.invalidate(myOrdersProvider)))
            : ListView(
                padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, Space.xxl),
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  Skeleton(width: 150, height: 30, radius: 99),
                  SizedBox(height: Space.lg),
                  Skeleton(height: 72, radius: Radii.md),
                  SizedBox(height: Space.md),
                  Skeleton(height: 300, radius: Radii.lg),
                  SizedBox(height: Space.md),
                  Skeleton(height: 52, radius: Radii.md),
                ],
              ),
      );
    }

    final (label, color) = orderStatusLabel(s, o, c);
    final quotes = o.latestQuotes;
    final readyQuotes = quotes.where((q) => q.allPriced).toList();
    final unpricedTotal = quotes.fold(0, (a, q) => a + q.unpricedCount);
    final canDecide = o.status == 'quote_sent' && o.acceptedVersion == null;
    // Kuzatish — buyurtma ishga tushgach: oddiy buyurtma yoki qabul qilingan KP.
    final tracked = !o.isQuote || o.acceptedVersion != null;

    return Scaffold(
      appBar: AppBar(title: Text('${o.wasQuote ? s.quoteLabel : s.orderLabel} #${o.id}')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myOrdersProvider.future).catchError((_) => <Order>[]),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, Space.xxl),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
                  child: Text(label, style: context.text.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                Text(_date(o.createdAt), style: context.text.bodySmall),
              ],
            ),
            const SizedBox(height: Space.lg),
            if (tracked && o.status != 'cancelled') OrderTrackingSection(orderId: o.id),
            if (o.isQuote && quotes.isEmpty)
              _Banner(icon: Icons.hourglass_top_rounded, text: s.kpPreparing, color: const Color(0xFFE08A00)),
            // Narx kutilayotgan qatorlar bitta qatorda: xaridor do'konlarni emas,
            // Climaventni ko'radi (egasi, 24.09.2026).
            if (unpricedTotal > 0)
              _Banner(
                icon: Icons.hourglass_top_rounded,
                text: s.kpWaitingCount(unpricedTotal),
                color: const Color(0xFFE08A00),
              ),
            for (final q in quotes) ...[
              if (q.expired && canDecide)
                _Banner(icon: Icons.event_busy_rounded, text: s.kpExpired, color: c.danger),
              _KpDocument(order: o, quote: q),
              const SizedBox(height: Space.md),
            ],
            if (quotes.isEmpty) _ItemsCard(order: o),
            // Hujjat faqat tayyor bo'limlardan quriladi — bittasi ham tayyor bo'lmasa tugma yo'q.
            if (readyQuotes.isNotEmpty) ...[
              OutlinedButton.icon(
                onPressed: _pdfBusy ? null : () => _pdf(o, quotes),
                icon: _pdfBusy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(s.kpDownloadPdf),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: c.textPrimary,
                  side: BorderSide(color: c.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
                ),
              ),
              const SizedBox(height: Space.sm),
            ],
            if (canDecide && quotes.isNotEmpty) ...[
              if (quotes.any((q) => q.expired))
                PrimaryButton(
                  label: s.kpRequestAgain,
                  loading: _busy,
                  onPressed: () => _run(() => ref.read(orderRepositoryProvider).requestAgain(o.id), s.kpRequestedAgain),
                )
              else if (quotes.every((q) => q.allPriced)) ...[
                PrimaryButton(label: s.kpAccept, loading: _busy, onPressed: () => _accept(o, quotes.first)),
                const SizedBox(height: Space.xs),
                GhostButton(label: s.kpReject, onPressed: _busy ? null : () => _reject(o)),
              ],
            ],
            const SizedBox(height: Space.lg),
            _Details(order: o),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: Space.md),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(Radii.md)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: context.text.bodyMedium?.copyWith(color: context.colors.textPrimary))),
          ],
        ),
      );
}

/// KP — qog'oz hujjatga o'xshash karta.
class _KpDocument extends StatelessWidget {
  const _KpDocument({required this.order, required this.quote});
  final Order order;
  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final q = quote;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: c.border),
        boxShadow: [BoxShadow(color: Brand.navy.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0A3A73), Brand.navy]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
            ),
            child: Row(
              children: [
                const Icon(Icons.request_quote_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.kpTitle, style: context.text.titleMedium?.copyWith(color: Colors.white)),
                      Text('KP-${order.id}-v${q.version}',
                          style: context.text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.75))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(s.kpValidUntil, style: context.text.bodySmall?.copyWith(color: Colors.white70)),
                    Text(_date(q.validUntil),
                        style: context.text.titleMedium?.copyWith(color: q.expired ? const Color(0xFFFF8A85) : Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < q.items.length; i++) ...[
                  if (i > 0) Divider(height: Space.lg, color: c.border),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(q.items[i].name, style: context.text.bodyMedium?.copyWith(color: c.textPrimary)),
                            if (q.items[i].model.isNotEmpty) Text(q.items[i].model, style: context.text.bodySmall),
                            const SizedBox(height: 2),
                            Text(
                              q.items[i].price == null
                                  ? '${q.items[i].qty} × ${s.kpUnpricedCell}'
                                  : '${q.items[i].qty} × ${sumText(context, q.items[i].price!.round())}',
                              style: context.text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        q.items[i].sum == null ? '—' : sumText(context, q.items[i].sum!.round()),
                        style: context.text.titleMedium,
                      ),
                    ],
                  ),
                ],
                Divider(height: Space.xl, color: c.border),
                Row(
                  children: [
                    Expanded(child: Text(s.cartTotal, style: context.text.titleMedium)),
                    Text(sumText(context, q.total.round()), style: context.text.headlineSmall),
                  ],
                ),
                if (q.deliveryTerms != null) _Term(title: s.kpDeliveryTerms, text: q.deliveryTerms!),
                if (q.paymentTerms != null) _Term(title: s.kpPaymentTerms, text: q.paymentTerms!),
                if (q.note != null) _Term(title: s.commentTitle, text: q.note!),
                const SizedBox(height: Space.md),
                Text(s.kpDisclaimer, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Term extends StatelessWidget {
  const _Term({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Space.md),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: '$title: ', style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
          TextSpan(text: text, style: context.text.bodyMedium),
        ])),
      );
}

/// KP hali yo'q yoki oddiy buyurtma — qatorlar ro'yxati.
class _ItemsCard extends ConsumerWidget {
  const _ItemsCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final c = context.colors;
    final lang = ref.watch(langProvider);
    final products = ref.watch(productsProvider).value ?? const <Product>[];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < order.items.length; i++) ...[
            if (i > 0) Divider(height: Space.lg, color: c.border),
            Builder(builder: (_) {
              final it = order.items[i];
              final p = it.productId == 0 ? null : products.where((x) => x.id == it.productId).firstOrNull;
              return Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFFF4F6FA), borderRadius: BorderRadius.circular(10)),
                    // Xizmat qatori (№39) — mahsulot emas, belgi.
                    child: it.productId == 0
                        ? const Icon(Icons.build_rounded, color: Brand.navy)
                        : NetImage(p?.cover, width: 160),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p?.name.of(lang) ?? it.model,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: context.text.bodyMedium?.copyWith(color: c.textPrimary)),
                        Text('${it.model} · ${it.qty}', style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(it.price == null ? s.priceAwaited : sumText(context, (it.price! * it.qty).round()),
                      style: it.price == null ? context.text.bodySmall : context.text.titleMedium),
                ],
              );
            }),
          ],
          if (order.total != null) ...[
            Divider(height: Space.xl, color: c.border),
            Row(children: [
              Expanded(child: Text(s.cartTotal, style: context.text.titleMedium)),
              Text(sumText(context, order.total!.round()), style: context.text.headlineSmall),
            ]),
          ],
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final rows = <(IconData, String)>[
      if (order.location != null) (Icons.location_on_outlined, [order.location, order.addressDetails].whereType<String>().join(', ')),
      if (order.recipientName != null || order.recipientPhone != null)
        (Icons.person_outline_rounded, [order.recipientName, order.recipientPhone].whereType<String>().join(' · ')),
      if (order.companyName != null)
        (Icons.business_outlined, [order.companyName, if (order.companyTin != null) '${s.companyTin} ${order.companyTin}'].whereType<String>().join(' · ')),
      if (order.comment != null) (Icons.chat_bubble_outline_rounded, order.comment!),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(r.$1, size: 20, color: c.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(r.$2, style: context.text.bodyMedium?.copyWith(color: c.textPrimary))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
