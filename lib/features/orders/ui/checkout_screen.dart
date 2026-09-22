import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/api/api_client.dart';
import '../../../core/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/phone_input.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/cart_resolved.dart';
import '../../catalog/catalog_providers.dart';
import '../../catalog/ui/widgets.dart';
import '../data/order_models.dart';
import '../data/order_repository.dart';
import '../orders_providers.dart';
import 'map_picker_screen.dart';

/// Rasmiylashtirish: `kind=order` — sotib olish, `kind=quote` — KP so'rovi.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.kind});
  final String kind;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _details = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController();
  final _tin = TextEditingController();
  final _comment = TextEditingController();
  LatLng? _point;
  bool _sending = false;
  bool _prefilled = false;
  bool _nameTouched = false;

  bool get _quote => widget.kind == 'quote';

  @override
  void dispose() {
    for (final c in [_address, _details, _name, _phone, _company, _tin, _comment]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill() {
    if (_prefilled) return;
    final session = ref.read(sessionProvider);
    final profile = ref.read(profileProvider);
    if (session == null) return;
    _prefilled = true;
    _name.text = profile?.displayName ?? '';
    final d = session.phone.replaceAll(RegExp(r'\D'), '');
    _phone.text = formatUzPhone(d.startsWith('998') ? d.substring(3) : d);
  }

  Future<void> _pickOnMap() async {
    final r = await Navigator.of(context).push<PickedPlace>(
      MaterialPageRoute(builder: (_) => MapPickerScreen(initial: _point), fullscreenDialog: true),
    );
    if (r == null) return;
    setState(() {
      _point = r.point;
      if (r.address != null && r.address!.isNotEmpty) _address.text = r.address!;
    });
  }

  Future<void> _submit(List<ResolvedLine> lines) async {
    final s = S.of(context);
    if (!(_form.currentState?.validate() ?? false)) {
      HapticFeedback.mediumImpact();
      return;
    }
    final session = ref.read(sessionProvider);
    if (session == null) return;
    setState(() => _sending = true);
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    final form = CheckoutForm(
      kind: widget.kind,
      address: _address.text,
      details: _details.text,
      lat: _point?.latitude,
      lng: _point?.longitude,
      recipientName: _name.text,
      recipientPhone: '+998$digits',
      comment: _comment.text,
      companyName: _company.text,
      companyTin: _tin.text,
    );
    // Aralash savat — har do'kon uchun alohida buyurtma (sayt ham shunday).
    final byStore = <int, List<ResolvedLine>>{};
    for (final l in lines) {
      byStore.putIfAbsent(l.product.store?.id ?? 0, () => []).add(l);
    }
    final created = <Order>[];
    try {
      for (final group in byStore.values) {
        final order = await ref.read(orderRepositoryProvider).create(
              userId: session.userId,
              f: form,
              lines: [
                for (final l in group)
                  OrderLine(
                    productId: l.product.id,
                    modelTitle: l.modelTitle,
                    qty: l.line.qty,
                    modelId: l.model?.id,
                    variantId: l.variant?.id,
                  ),
              ],
            );
        created.add(order);
        // Yuborilgan do'kon qatorlari savatdan olinadi — xato bo'lsa qolganlari saqlanadi.
        for (final l in group) {
          ref.read(cartProvider.notifier).remove(l.line.key);
        }
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ref.invalidate(myOrdersProvider);
      if (_quote) {
        // KP darhol tayyor (backend №28) — to'g'ri hujjat sahifasiga.
        final first = created.first;
        // Bu ekran yopiladi — shuning uchun context emas, router orqali ochamiz.
        final router = GoRouter.of(context);
        router.go('/orders');
        Future.microtask(() => router.push('/order/${first.id}', extra: first));
      } else {
        context.go('/checkout/done?kind=order&ids=${created.map((o) => o.id).join(',')}');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      showSnack(context,
          created.isEmpty ? errorText(context, e) : s.checkoutPartial(created.map((o) => o.id).join(', #')),
          icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final session = ref.watch(sessionProvider);
    final lines = ref.watch(resolvedCartProvider);
    final rate = ref.watch(usdRateProvider).value;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_quote ? s.checkoutQuote : s.checkoutOrder)),
        body: Padding(
          padding: const EdgeInsets.all(Space.gutter),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 48, color: c.textTertiary),
              const SizedBox(height: Space.lg),
              Text(s.checkoutLoginTitle, style: context.text.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: Space.sm),
              Text(s.checkoutLoginBody, style: context.text.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: Space.xl),
              PrimaryButton(
                label: s.signIn,
                onPressed: () => context.push('/auth/phone?next=${Uri.encodeComponent('/checkout?kind=${widget.kind}')}'),
              ),
            ],
          ),
        ),
      );
    }
    _prefill();
    // Profil fonda yuklanadi — kelganda bo'sh ism maydonini to'ldiramiz.
    final profileName = ref.watch(profileProvider)?.displayName ?? '';
    if (_name.text.isEmpty && profileName.isNotEmpty && !_nameTouched) _name.text = profileName;

    final priced = lines.where((l) => l.price != null);
    final unpriced = lines.length - priced.length;
    final total = rate == null ? null : priced.fold<int>(0, (a, l) => a + rate.toSum(l.price!.effective) * l.line.qty);
    final stores = lines.map((l) => l.product.store?.id).toSet().length;

    return Scaffold(
      appBar: AppBar(title: Text(_quote ? s.checkoutQuoteTitle : s.checkoutOrderTitle)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.xxl),
          children: [
            if (_quote) ...[
              _Note(icon: Icons.request_quote_outlined, text: s.checkoutQuoteNote),
              const SizedBox(height: Space.lg),
            ],
            _Section(title: _quote ? s.deliveryAddressOptional : s.deliveryAddress),
            _MapTile(point: _point, onTap: _pickOnMap),
            const SizedBox(height: Space.md),
            TextFormField(
              controller: _address,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: s.addressLabel),
              validator: (v) => !_quote && (v ?? '').trim().length < 3 ? s.addressRequired : null,
            ),
            const SizedBox(height: Space.md),
            TextFormField(
              controller: _details,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: s.addressDetailsLabel),
            ),
            const SizedBox(height: Space.xl),
            _Section(title: s.recipientTitle),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => _nameTouched = true,
              decoration: InputDecoration(labelText: s.recipientName),
              validator: (v) => (v ?? '').trim().length < 2 ? s.firstNameRequired : null,
            ),
            const SizedBox(height: Space.md),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [UzPhoneFormatter()],
              decoration: InputDecoration(labelText: s.phoneLabel, prefixText: '+998 '),
              validator: (v) => isValidUzMobile((v ?? '').replaceAll(RegExp(r'\D'), '')) ? null : s.phoneInvalid,
            ),
            if (_quote) ...[
              const SizedBox(height: Space.xl),
              _Section(title: s.companyTitle),
              TextFormField(
                controller: _company,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: s.companyName),
              ),
              const SizedBox(height: Space.md),
              TextFormField(
                controller: _tin,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                decoration: InputDecoration(labelText: s.companyTin),
                validator: (v) => (v ?? '').isEmpty || v!.length == 9 ? null : s.companyTinInvalid,
              ),
            ],
            const SizedBox(height: Space.xl),
            _Section(title: s.commentTitle),
            TextFormField(
              controller: _comment,
              maxLines: 3,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: s.commentHint),
            ),
            const SizedBox(height: Space.lg),
            _Summary(count: lines.fold(0, (a, l) => a + l.line.qty), total: total, unpriced: unpriced, stores: stores),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.md + MediaQuery.paddingOf(context).bottom),
        decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
        child: PrimaryButton(
          label: _quote ? s.sendQuoteRequest : s.confirmOrder,
          loading: _sending,
          onPressed: lines.isEmpty ? null : () => _submit(lines),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Space.md),
        child: Text(title, style: context.text.titleMedium),
      );
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Brand.mist.withValues(alpha: dark ? 0.12 : 0.45),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: dark ? Brand.sky : Brand.navy),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: context.text.bodyMedium?.copyWith(color: context.colors.textPrimary))),
        ],
      ),
    );
  }
}

/// Kichik xarita: nuqta tanlangan bo'lsa — o'sha joy, bo'lmasa — "xaritada belgilash".
class _MapTile extends StatelessWidget {
  const _MapTile({required this.point, required this.onTap});
  final LatLng? point;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.lg),
      child: SizedBox(
        height: 140,
        child: Stack(
          children: [
            if (point != null)
              IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(initialCenter: point!, initialZoom: 16),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'uz.climavent.app',
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: point!,
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: const Icon(Icons.location_on_rounded, color: Brand.flame, size: 40),
                      ),
                    ]),
                  ],
                ),
              )
            else
              Container(
                color: c.surfaceMuted,
                alignment: Alignment.center,
                child: Icon(Icons.map_outlined, size: 44, color: c.textTertiary),
              ),
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: onTap),
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(point == null ? Icons.add_location_alt_outlined : Icons.edit_location_alt_outlined,
                          size: 18, color: c.textPrimary),
                      const SizedBox(width: 6),
                      Text(point == null ? s.mapPick : s.mapChange,
                          style: context.text.bodyMedium?.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.count, required this.total, required this.unpriced, required this.stores});
  final int count;
  final int? total;
  final int unpriced;
  final int stores;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
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
          Row(
            children: [
              Expanded(child: Text(s.itemsCount(count), style: context.text.bodyMedium)),
              if (total != null && total! > 0) Text(sumText(context, total!), style: context.text.titleLarge),
            ],
          ),
          if (unpriced > 0) ...[
            const SizedBox(height: 4),
            Text(s.cartUnpriced(unpriced), style: context.text.bodySmall),
          ],
          if (stores > 1) ...[
            const SizedBox(height: Space.sm),
            Text(s.checkoutSplit(stores), style: context.text.bodySmall),
          ],
          const SizedBox(height: Space.sm),
          Text(s.paymentNote, style: context.text.bodySmall),
        ],
      ),
    );
  }
}
