import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/buttons.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/catalog_providers.dart';
import '../../catalog/data/models.dart';
import '../../catalog/ui/widgets.dart';
import '../data/order_models.dart';
import '../orders_providers.dart';

class OrdersTab extends ConsumerWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final c = context.colors;
    final session = ref.watch(sessionProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.tabOrders)),
        body: _Empty(
          icon: Icons.receipt_long_outlined,
          title: s.ordersLoginTitle,
          body: s.ordersLoginBody,
          action: s.signIn,
          onAction: () => context.push('/auth/phone?next=%2Forders'),
        ),
      );
    }

    final orders = ref.watch(myOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.tabOrders)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myOrdersProvider.future).catchError((_) => <Order>[]),
        child: orders.when(
          loading: () => ListView.separated(
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, Space.xxl),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
            itemBuilder: (_, _) => const Skeleton(height: 150, radius: Radii.lg),
          ),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 120),
            ErrorRetry(error: e, onRetry: () => ref.invalidate(myOrdersProvider)),
          ]),
          data: (list) {
            if (list.isEmpty) {
              return ListView(children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.7,
                  child: _Empty(
                    icon: Icons.receipt_long_outlined,
                    title: s.ordersEmptyTitle,
                    body: s.ordersEmptyBody,
                    action: s.goToCatalog,
                    onAction: () => context.go('/catalog'),
                  ),
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, Space.xxl),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
              itemBuilder: (_, i) => _OrderCard(order: list[i], c: c),
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order, required this.c});
  final Order order;
  final AppColors c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final o = order;
    final lang = ref.watch(langProvider);
    final products = ref.watch(productsProvider).value ?? const <Product>[];
    Product? productOf(int id) => products.where((p) => p.id == id).firstOrNull;
    final (label, color) = orderStatusLabel(s, o, c);
    final date = o.createdAt == null
        ? ''
        : '${o.createdAt!.day.toString().padLeft(2, '0')}.${o.createdAt!.month.toString().padLeft(2, '0')}.${o.createdAt!.year}';
    final first = o.items.isEmpty ? null : o.items.first;
    final firstName = first == null ? '' : (productOf(first.productId)?.name.of(lang) ?? first.model);
    final shown = o.items.take(4).toList();
    final extra = o.items.length - shown.length;
    final pieces = o.items.fold<int>(0, (a, i) => a + i.qty);

    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(Radii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: () => context.push('/order/${o.id}', extra: o),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(o.isQuote ? Icons.request_quote_outlined : Icons.shopping_bag_outlined,
                      size: 20, color: c.textSecondary),
                  const SizedBox(width: 8),
                  Text('${o.isQuote ? s.quoteLabel : s.orderLabel} #${o.id}', style: context.text.titleMedium),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
                    child: Text(label, style: context.text.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              // Mahsulot rasmlari — qaysi buyurtma ekanini bir qarashda tanish uchun.
              Row(
                children: [
                  for (final it in shown) ...[
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
                      child: NetImage(productOf(it.productId)?.cover, width: 160),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (extra > 0)
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(12)),
                      child: Text('+$extra', style: context.text.titleMedium?.copyWith(color: c.textSecondary)),
                    ),
                ],
              ),
              const SizedBox(height: Space.md),
              Text(
                o.items.length > 1 ? s.orderItemsSummary(firstName, o.items.length - 1) : firstName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium?.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: Space.sm),
              Row(
                children: [
                  Text('$date · ${s.piecesCount(pieces)}', style: context.text.bodySmall),
                  const Spacer(),
                  Text(
                    o.total != null && o.total! > 0 ? sumText(context, o.total!.round()) : s.priceAwaited,
                    style: o.total != null && o.total! > 0
                        ? context.text.titleMedium
                        : context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

(String, Color) orderStatusLabel(S s, Order o, AppColors c) => switch (o.status) {
      'new' when o.isQuote && o.latestQuotes.any((q) => q.expired) => (s.statusQuoteExpired, c.danger),
      'new' when o.isQuote => (s.statusQuotePending, const Color(0xFFE08A00)),
      'quote_sent' when o.latestQuotes.any((q) => q.expired) => (s.statusQuoteExpired, c.danger),
      'new' => (s.statusNew, Brand.link),
      'quote_sent' => (s.statusQuoteReady, c.success),
      'paid' => (s.statusPaid, c.success),
      'shipping' => (s.statusShipping, Brand.link),
      'done' => (s.statusDone, c.success),
      'cancelled' || 'canceled' => (s.statusCancelled, c.danger),
      _ => (o.status, c.textSecondary),
    };

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.body, required this.action, required this.onAction});
  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
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
              child: Icon(icon, size: 46, color: dark ? Brand.sky : Brand.navy),
            ),
            const SizedBox(height: Space.xl),
            Text(title, textAlign: TextAlign.center, style: context.text.titleLarge),
            const SizedBox(height: Space.sm),
            Text(body, textAlign: TextAlign.center, style: context.text.bodyMedium),
            const SizedBox(height: Space.xl),
            SizedBox(width: 220, child: PrimaryButton(label: action, onPressed: onAction)),
          ],
        ),
      ),
    );
  }
}
