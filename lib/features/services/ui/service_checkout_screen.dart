import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../catalog/catalog_providers.dart';
import '../../catalog/ui/widgets.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/orders_providers.dart';
import '../../orders/ui/map_picker_screen.dart';
import '../data/service_models.dart';
import '../services_providers.dart';
import 'service_widgets.dart';
import 'visit_picker.dart';

/// Xizmatga buyurtma: qayerga (hudud majburiy), qachon (mijoz taklifi), kim qabul qiladi.
class ServiceCheckoutScreen extends ConsumerStatefulWidget {
  const ServiceCheckoutScreen({super.key, required this.serviceId, required this.variantId, required this.qty});
  final int serviceId;
  final int variantId;
  final int qty;

  @override
  ConsumerState<ServiceCheckoutScreen> createState() => _ServiceCheckoutScreenState();
}

class _ServiceCheckoutScreenState extends ConsumerState<ServiceCheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _details = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _comment = TextEditingController();
  LatLng? _point;
  ServiceArea? _area;
  VisitSlot? _slot;
  bool _sending = false;
  bool _prefilled = false;
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    final a = ref.read(serviceAreaProvider);
    // Tumani tanlangan saqlangan hudud — oldindan to'ldiriladi.
    if (a.district != null) _area = a;
  }

  @override
  void dispose() {
    for (final c in [_address, _details, _name, _phone, _comment]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill() {
    if (_prefilled) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    _prefilled = true;
    _name.text = ref.read(profileProvider)?.displayName ?? '';
    final d = session.phone.replaceAll(RegExp(r'\D'), '');
    _phone.text = formatUzPhone(d.startsWith('998') ? d.substring(3) : d);
  }

  Future<void> _pickArea() async {
    final a = await pickServiceArea(context, requireDistrict: true, initial: _area);
    if (a == null) return;
    setState(() => _area = a);
    ref.read(serviceAreaProvider.notifier).set(a);
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

  Future<void> _submit(ServiceOffer o) async {
    final s = S.of(context);
    setState(() => _tried = true);
    final ok = _form.currentState?.validate() ?? false;
    if (!ok || _area == null || _slot == null) {
      HapticFeedback.mediumImpact();
      return;
    }
    final session = ref.read(sessionProvider);
    if (session == null) return;
    setState(() => _sending = true);
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    try {
      final order = await ref.read(orderRepositoryProvider).create(
            userId: session.userId,
            f: CheckoutForm(
              kind: 'order',
              address: _address.text,
              details: _details.text,
              lat: _point?.latitude,
              lng: _point?.longitude,
              recipientName: _name.text,
              recipientPhone: '+998$digits',
              service: ServiceVisit(
                regionCode: _area!.region,
                districtCode: _area!.district,
                date: _slot!.day,
                windowFrom: _slot!.from,
                windowTo: _slot!.to,
                comment: _comment.text,
              ),
            ),
            lines: [OrderLine.service(serviceId: o.id, serviceVariantId: widget.variantId, qty: widget.qty)],
          );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ref.invalidate(myOrdersProvider);
      showSnack(context, s.serviceBooked, icon: Icons.check_circle_outline_rounded);
      final router = GoRouter.of(context);
      router.go('/orders');
      Future.microtask(() => router.push('/order/${order.id}', extra: order));
    } on ApiException catch (e) {
      if (!mounted) return;
      showSnack(context, e.status == 409 && (e.message ?? '').isEmpty ? s.serviceNotInArea : errorText(context, e),
          icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final lang = ref.watch(langProvider);
    final session = ref.watch(sessionProvider);
    final async = ref.watch(serviceDetailProvider(widget.serviceId));
    final regions = ref.watch(regionsProvider).value ?? const <Region>[];

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.serviceCheckoutTitle)),
        body: Padding(
          padding: const EdgeInsets.all(Space.gutter),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 48, color: c.textTertiary),
              const SizedBox(height: Space.lg),
              Text(s.checkoutLoginTitle, style: context.text.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: Space.xl),
              PrimaryButton(
                label: s.signIn,
                onPressed: () => context.push(
                  '/auth/phone?next=${Uri.encodeComponent('/service/${widget.serviceId}/book?v=${widget.variantId}&q=${widget.qty}')}',
                ),
              ),
            ],
          ),
        ),
      );
    }
    _prefill();

    final o = async.value;
    if (o == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.serviceCheckoutTitle)),
        body: async.hasError
            ? Center(child: ErrorRetry(error: async.error!, onRetry: () => ref.invalidate(serviceDetailProvider(widget.serviceId))))
            : const Center(child: CircularProgressIndicator()),
      );
    }
    final v = o.variants.where((x) => x.id == widget.variantId).firstOrNull;
    final total = v?.price == null ? null : v!.price! * widget.qty;

    return Scaffold(
      appBar: AppBar(title: Text(s.serviceCheckoutTitle)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.xxl),
          children: [
            // Nima buyurtma qilinyapti.
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Icon(serviceIcon(o.category?.key ?? ''), color: Theme.of(context).brightness == Brightness.dark ? Brand.sky : Brand.navy),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.name.of(lang), style: context.text.titleMedium),
                        Text(
                          [if (v != null && o.variants.length > 1) v.name.of(lang), if (widget.qty > 1) '× ${widget.qty}', o.provider?.name]
                              .whereType<String>()
                              .where((e) => e.isNotEmpty)
                              .join(' · '),
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    o.isQuote || total == null ? s.serviceByQuote : (o.isFrom ? s.serviceFrom(sumText(context, total)) : sumText(context, total)),
                    style: context.text.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.xl),
            Text(s.serviceWhere, style: context.text.titleMedium),
            const SizedBox(height: Space.md),
            _AreaField(
              text: _area == null ? null : areaName(regions, _area!, lang),
              error: _tried && _area == null ? s.serviceDistrictRequired : null,
              onTap: _pickArea,
            ),
            const SizedBox(height: Space.md),
            TextFormField(
              controller: _address,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: s.addressLabel,
                suffixIcon: IconButton(
                  tooltip: s.mapPick,
                  onPressed: _pickOnMap,
                  icon: Icon(_point == null ? Icons.add_location_alt_outlined : Icons.edit_location_alt_outlined),
                ),
              ),
              validator: (x) => (x ?? '').trim().length < 3 ? s.addressRequired : null,
            ),
            const SizedBox(height: Space.md),
            TextFormField(
              controller: _details,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: s.addressDetailsLabel),
            ),
            const SizedBox(height: Space.xl),
            Text(s.serviceWhen, style: context.text.titleMedium),
            const SizedBox(height: 2),
            Text(s.serviceWhenNote, style: context.text.bodySmall),
            const SizedBox(height: Space.md),
            VisitPicker(onChanged: (x) => setState(() => _slot = x)),
            if (_tried && _slot == null) ...[
              const SizedBox(height: 6),
              Text(s.serviceTimeRequired, style: context.text.bodySmall?.copyWith(color: c.danger)),
            ],
            const SizedBox(height: Space.xl),
            Text(s.recipientTitle, style: context.text.titleMedium),
            const SizedBox(height: Space.md),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: s.recipientName),
              validator: (x) => (x ?? '').trim().length < 2 ? s.firstNameRequired : null,
            ),
            const SizedBox(height: Space.md),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [UzPhoneFormatter()],
              decoration: InputDecoration(labelText: s.phoneLabel, prefixText: '+998 '),
              validator: (x) => isValidUzMobile((x ?? '').replaceAll(RegExp(r'\D'), '')) ? null : s.phoneInvalid,
            ),
            const SizedBox(height: Space.xl),
            Text(s.commentTitle, style: context.text.titleMedium),
            const SizedBox(height: Space.md),
            TextFormField(
              controller: _comment,
              maxLines: 3,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: s.commentHint),
            ),
            if (o.isFrom) Text(s.serviceFromNote, style: context.text.bodySmall),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.md + MediaQuery.paddingOf(context).bottom),
        decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
        child: PrimaryButton(
          label: o.isQuote ? s.serviceAskPrice : s.serviceOrder,
          loading: _sending,
          onPressed: () => _submit(o),
        ),
      ),
    );
  }
}

class _AreaField extends StatelessWidget {
  const _AreaField({required this.text, required this.onTap, this.error});
  final String? text;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: s.serviceArea,
          errorText: error,
          suffixIcon: const Icon(Icons.expand_more_rounded),
        ),
        isEmpty: text == null,
        child: text == null ? null : Text(text!, style: context.text.bodyLarge),
      ),
    );
  }
}
