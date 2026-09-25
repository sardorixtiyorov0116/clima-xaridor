import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/feedback.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/catalog_providers.dart';
import '../../catalog/ui/widgets.dart';
import '../../chat/chat_socket.dart';
import '../data/tracking_models.dart';
import '../orders_providers.dart';

const _amber = Color(0xFFE08A00);

String _two(int v) => v.toString().padLeft(2, '0');
String _time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';
String _day(DateTime d) => '${_two(d.day)}.${_two(d.month)}';
String _dayTime(DateTime d) => '${_day(d)} ${_time(d)}';

/// "28.09, 10:00–13:00" — bir kunda bo'lsa bitta sana.
String _window(DateTime? a, DateTime? b) {
  if (a == null) return '—';
  if (b == null) return _dayTime(a);
  return a.day == b.day && a.month == b.month ? '${_day(a)}, ${_time(a)}–${_time(b)}' : '${_dayTime(a)} – ${_dayTime(b)}';
}

/// Buyurtma sahifasidagi kuzatish bloki (№38, №39): bosqichlar, kuryer xaritada,
/// usta ishi. Backend javob bermasa jim — sahifa avvalgidek ishlaydi.
///
/// Yangilanish: jonli joylashuv bor paytda 15 soniyada bir (ekran ochiq bo'lsa),
/// qolgan paytda faqat socket signali (`order_updated`) kelganda.
class OrderTrackingSection extends ConsumerStatefulWidget {
  const OrderTrackingSection({super.key, required this.orderId});
  final int orderId;

  @override
  ConsumerState<OrderTrackingSection> createState() => _OrderTrackingSectionState();
}

class _OrderTrackingSectionState extends ConsumerState<OrderTrackingSection> with WidgetsBindingObserver {
  Timer? _timer;
  StreamSubscription<int>? _sub;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = ref.read(chatSocketProvider).orderUpdates.where((id) => id == widget.orderId).listen((_) => _reload());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    _foreground = s == AppLifecycleState.resumed;
    if (_foreground) _reload();
  }

  void _reload() {
    if (mounted) ref.invalidate(orderTrackingProvider(widget.orderId));
  }

  void _schedule(bool live) {
    if (live && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (_foreground) _reload();
      });
    } else if (!live && _timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(orderTrackingProvider(widget.orderId));
    final t = async.value;
    // Timer holatni `build` dan keyin moslaymiz — build ichida yon ta'sir bo'lmasin.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _schedule(t?.live ?? false);
    });
    if (t == null) {
      return async.isLoading ? const Padding(padding: EdgeInsets.only(bottom: Space.md), child: Skeleton(height: 120, radius: Radii.lg)) : const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepsCard(tracking: t),
        for (final p in t.parts) ...[
          if (p.delivery != null) _DeliveryCard(part: p, delivery: p.delivery!),
          for (final j in p.jobs) JobCard(orderId: t.orderId, job: j, storeName: p.storeName),
        ],
      ],
    );
  }
}

/* ───────────────────────── Bosqichlar ───────────────────────── */

class _StepsCard extends StatelessWidget {
  const _StepsCard({required this.tracking});
  final OrderTracking tracking;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final steps = tracking.steps.where((x) => x.key.isNotEmpty).toList();
    if (steps.isEmpty) return const SizedBox.shrink();
    final cancelled = steps.any((x) => x.key == 'cancelled');
    // Joriy qadam — vaqti bor oxirgi qadam.
    final current = steps.lastIndexWhere((x) => x.at != null);

    String label(String k) => switch (k) {
          'created' => s.trackCreated,
          'packing' => s.trackPacking,
          'ready' => s.trackReady,
          'shipping' => s.trackShipping,
          'in_progress' => s.trackInProgress,
          'done' => s.trackDone,
          'cancelled' => s.trackCancelled,
          _ => k,
        };
    IconData icon(String k) => switch (k) {
          'created' => Icons.receipt_long_rounded,
          'packing' => Icons.inventory_2_outlined,
          'ready' => Icons.inventory_rounded,
          'shipping' => Icons.local_shipping_rounded,
          'in_progress' => Icons.build_rounded,
          'done' => Icons.check_rounded,
          'cancelled' => Icons.close_rounded,
          _ => Icons.circle_outlined,
        };

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.trackTitle, style: context.text.titleMedium),
          const SizedBox(height: Space.md),
          for (var i = 0; i < steps.length; i++)
            _StepRow(
              label: label(steps[i].key),
              icon: icon(steps[i].key),
              at: steps[i].at,
              state: steps[i].key == 'cancelled'
                  ? _Step.bad
                  : i < current
                      ? _Step.done
                      : i == current
                          ? (steps[i].key == 'done' ? _Step.done : (cancelled ? _Step.done : _Step.now))
                          : _Step.todo,
              last: i == steps.length - 1,
              color: c,
            ),
        ],
      ),
    );
  }
}

enum _Step { done, now, todo, bad }

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.icon,
    required this.at,
    required this.state,
    required this.last,
    required this.color,
  });
  final String label;
  final IconData icon;
  final DateTime? at;
  final _Step state;
  final bool last;
  final AppColors color;

  @override
  Widget build(BuildContext context) {
    final c = color;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? Brand.sky : Brand.link;
    final (bg, fg) = switch (state) {
      _Step.done => (c.success.withValues(alpha: 0.14), c.success),
      _Step.now => (accent, Colors.white),
      _Step.bad => (c.danger.withValues(alpha: 0.14), c.danger),
      _Step.todo => (c.surfaceMuted, c.textTertiary),
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                _Pulse(
                  active: state == _Step.now,
                  color: accent,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                    child: Icon(state == _Step.done ? Icons.check_rounded : icon, size: 17, color: fg),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: state == _Step.done ? c.success.withValues(alpha: 0.5) : c.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 6, bottom: last ? 0 : Space.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: context.text.bodyMedium?.copyWith(
                        color: state == _Step.todo ? c.textTertiary : c.textPrimary,
                        fontWeight: state == _Step.now ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (at != null) Text(_dayTime(at!), style: context.text.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Joriy qadam atrofida yumshoq to'lqin.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.active, required this.color, required this.child});
  final bool active;
  final Color color;
  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    if (widget.active) _a.repeat();
  }

  @override
  void didUpdateWidget(covariant _Pulse old) {
    super.didUpdateWidget(old);
    if (widget.active && !_a.isAnimating) _a.repeat();
    if (!widget.active && _a.isAnimating) _a.stop();
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _a,
      builder: (_, child) => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.35 * (1 - _a.value)),
              blurRadius: 0,
              spreadRadius: 9 * _a.value,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/* ───────────────────────── Yetkazish ───────────────────────── */

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.part, required this.delivery});
  final TrackPart part;
  final TrackDelivery delivery;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final d = delivery;

    if (d.status == 'delivered') {
      return _Card(
        child: Row(
          children: [
            Icon(Icons.verified_rounded, color: c.success),
            const SizedBox(width: 10),
            Expanded(child: Text(s.trackDelivered, style: context.text.titleMedium?.copyWith(color: c.success))),
            if (d.deliveredAt != null) Text(_dayTime(d.deliveredAt!), style: context.text.bodySmall),
          ],
        ),
      );
    }
    if (const {'cancelled', 'returned', 'failed'}.contains(d.status)) return const SizedBox.shrink();

    if (!d.onTheWay) {
      return _Card(
        child: Row(
          children: [
            const Icon(Icons.local_shipping_outlined, color: _amber),
            const SizedBox(width: 10),
            Expanded(child: Text(s.trackCourierAssigned, style: context.text.bodyMedium?.copyWith(color: c.textPrimary))),
          ],
        ),
      );
    }

    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (d.location != null || d.destination != null)
            _LiveMap(
              mover: d.location?.point,
              destination: d.destination,
              moverIcon: d.vehicleType == 'foot'
                  ? Icons.directions_walk_rounded
                  : d.vehicleType == 'bike'
                      ? Icons.two_wheeler_rounded
                      : Icons.local_shipping_rounded,
              eta: d.eta,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PersonRow(
                  icon: Icons.local_shipping_rounded,
                  title: d.courierName ?? s.trackCourier,
                  subtitle: [s.trackCourier, if (d.vehicleText != null && d.vehicleText!.isNotEmpty) d.vehicleText!].join(' · '),
                  phone: d.courierPhone,
                ),
                if (d.location?.stale == true) ...[
                  const SizedBox(height: Space.sm),
                  Text(s.trackStale, style: context.text.bodySmall?.copyWith(color: _amber)),
                ],
                if (d.cod != null) ...[
                  const SizedBox(height: Space.md),
                  _Note(icon: Icons.payments_outlined, text: s.trackCash(sumText(context, d.cod!)), color: Brand.link),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Jonli xarita: kuryer/usta va manzil, ikkalasi sig'adigan masshtabda.
class _LiveMap extends StatelessWidget {
  const _LiveMap({required this.mover, required this.destination, required this.moverIcon, this.eta});
  final GeoPoint? mover;
  final GeoPoint? destination;
  final IconData moverIcon;
  final int? eta;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final pts = [mover, destination].whereType<GeoPoint>().map((p) => LatLng(p.lat, p.lng)).toList();
    final MapOptions opts;
    if (pts.length == 2 && (pts[0].latitude - pts[1].latitude).abs() + (pts[0].longitude - pts[1].longitude).abs() > 0.0005) {
      opts = MapOptions(
        initialCameraFit: CameraFit.coordinates(coordinates: pts, padding: const EdgeInsets.all(48), maxZoom: 16),
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
      );
    } else {
      opts = MapOptions(
        initialCenter: pts.first,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
      );
    }
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.lg)),
      child: SizedBox(
        height: 210,
        child: Stack(
          children: [
            FlutterMap(
              // Kalit nuqtaga bog'liq — yangi joylashuvda kamera qayta moslanadi.
              key: ValueKey('${mover?.lat},${mover?.lng}'),
              options: opts,
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'uz.climavent.app',
                ),
                if (mover != null && destination != null)
                  PolylineLayer(polylines: [
                    Polyline(
                      points: [LatLng(mover!.lat, mover!.lng), LatLng(destination!.lat, destination!.lng)],
                      color: Brand.link.withValues(alpha: 0.6),
                      strokeWidth: 3,
                      pattern: StrokePattern.dashed(segments: const [8, 6]),
                    ),
                  ]),
                MarkerLayer(markers: [
                  if (destination != null)
                    Marker(
                      point: LatLng(destination!.lat, destination!.lng),
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_on_rounded, color: Brand.flame, size: 40),
                    ),
                  if (mover != null)
                    Marker(
                      point: LatLng(mover!.lat, mover!.lng),
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Brand.navy,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8)],
                        ),
                        child: Icon(moverIcon, color: Colors.white, size: 20),
                      ),
                    ),
                ]),
              ],
            ),
            if (eta != null)
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded, size: 16, color: c.textPrimary),
                      const SizedBox(width: 6),
                      Text(s.trackEta(math.max(1, eta!)),
                          style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: c.textPrimary)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/* ───────────────────────── Usta ishi ───────────────────────── */

class JobCard extends ConsumerStatefulWidget {
  const JobCard({super.key, required this.orderId, required this.job, required this.storeName});
  final int orderId;
  final TrackJob job;
  final String storeName;

  @override
  ConsumerState<JobCard> createState() => _JobCardState();
}

class _JobCardState extends ConsumerState<JobCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() call, String ok) async {
    setState(() => _busy = true);
    try {
      await call();
      HapticFeedback.mediumImpact();
      ref.invalidate(orderTrackingProvider(widget.orderId));
      ref.invalidate(myOrdersProvider);
      if (mounted) showSnack(context, ok, icon: Icons.check_circle_outline_rounded);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, errorText(context, e), icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _ask(String title, String hint, {bool required = false}) async {
    final s = S.of(context);
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: ctx.text.titleLarge),
        content: TextField(controller: ctrl, maxLines: 3, maxLength: 500, decoration: InputDecoration(hintText: hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.jobRateSend)),
        ],
      ),
    );
    final text = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || (required && text.length < 3)) return null;
    return text;
  }

  Future<void> _rate() async {
    final s = S.of(context);
    final res = await showModalBottomSheet<(int, String)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _RateSheet(),
    );
    if (res == null) return;
    final repo = ref.read(orderRepositoryProvider);
    await _run(() => repo.reviewJob(widget.orderId, widget.job.id, res.$1, res.$2), s.jobRated);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final lang = ref.watch(langProvider);
    final j = widget.job;
    final repo = ref.read(orderRepositoryProvider);
    final (status, color) = _jobStatus(s, c, j.status);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if ((j.status == 'on_the_way' || j.status == 'arrived') && j.location != null)
            _LiveMap(mover: j.location!.point, destination: null, moverIcon: Icons.build_rounded, eta: j.status == 'on_the_way' ? j.eta : null),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Brand.mist.withValues(alpha: dark ? 0.15 : 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.build_rounded, color: dark ? Brand.sky : Brand.navy, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(j.isWarranty ? s.jobWarrantyTitle : s.jobTitle, style: context.text.titleMedium),
                          if (widget.storeName.isNotEmpty) Text(widget.storeName, style: context.text.bodySmall),
                        ],
                      ),
                    ),
                    _Chip(text: status, color: color),
                  ],
                ),
                const SizedBox(height: Space.md),
                for (final x in j.services)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      [x.name.of(lang), x.variant.of(lang)].where((e) => e.isNotEmpty).join(' · ') + (x.qty > 1 ? ' × ${x.qty}' : ''),
                      style: context.text.bodyMedium?.copyWith(color: c.textPrimary),
                    ),
                  ),
                const SizedBox(height: Space.sm),
                _InfoRow(
                  icon: Icons.event_rounded,
                  text: _window(j.from, j.to),
                  trailing: j.active && j.scheduleStatus != null
                      ? _Chip(
                          text: j.scheduleStatus == 'confirmed' ? s.jobTimeConfirmed : j.needsScheduleAnswer ? s.jobRescheduled : s.jobTimeProposed,
                          color: j.scheduleStatus == 'confirmed' ? c.success : _amber,
                        )
                      : null,
                ),
                if (j.needsScheduleAnswer && j.active) ...[
                  const SizedBox(height: Space.sm),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _busy ? null : () => _run(() => repo.answerSchedule(widget.orderId, j.id, accept: true), s.jobTimeConfirmed),
                          child: Text(s.jobTimeAccept),
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : () => _run(() => repo.answerSchedule(widget.orderId, j.id, accept: false), s.jobTimeRejected),
                          child: Text(s.jobTimeReject),
                        ),
                      ),
                    ],
                  ),
                ],
                if (j.workerName != null) ...[
                  const SizedBox(height: Space.md),
                  _PersonRow(
                    icon: Icons.engineering_rounded,
                    title: j.workerName!,
                    subtitle: j.status == 'on_the_way' && j.eta != null ? s.trackEta(j.eta!) : status,
                    phone: j.workerPhone,
                  ),
                ],
                if (j.pricePending && j.finalAmount != null) ...[
                  const SizedBox(height: Space.md),
                  _PriceApproval(
                    job: j,
                    busy: _busy,
                    onAccept: () => _run(() => repo.answerPrice(widget.orderId, j.id, accept: true), s.jobPriceAccepted),
                    onReject: () => _run(() => repo.answerPrice(widget.orderId, j.id, accept: false), s.jobPriceRejected),
                  ),
                ],
                if (j.proofCode != null && j.active) ...[
                  const SizedBox(height: Space.md),
                  _ProofCode(code: j.proofCode!),
                ],
                if (j.photosAfter.isNotEmpty) ...[
                  const SizedBox(height: Space.md),
                  Text(s.jobPhotosAfter, style: context.text.bodySmall),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: j.photosAfter.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(width: 72, child: NetImage(j.photosAfter[i], width: 200, fit: BoxFit.cover)),
                      ),
                    ),
                  ),
                ],
                if (j.warrantyUntil != null && j.status == 'completed') ...[
                  const SizedBox(height: Space.md),
                  _InfoRow(icon: Icons.verified_user_outlined, text: s.jobWarrantyUntil(_date(j.warrantyUntil!)), color: c.success),
                ],
                if (j.reviewRating != null) ...[
                  const SizedBox(height: Space.sm),
                  _InfoRow(icon: Icons.star_rounded, text: '${s.jobYourRating}: ${'★' * j.reviewRating!}', color: _amber),
                ],
                if (j.canReview || j.warrantyOpen || j.canCancel) const SizedBox(height: Space.md),
                if (j.canReview)
                  FilledButton.icon(
                    onPressed: _busy ? null : _rate,
                    icon: const Icon(Icons.star_rounded),
                    label: Text(s.jobRate),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  ),
                if (j.warrantyOpen)
                  TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () async {
                            final t = await _ask(s.jobWarrantyClaim, s.jobWarrantyHint, required: true);
                            if (t != null) await _run(() => repo.warrantyClaim(widget.orderId, j.id, t), s.jobWarrantySent);
                          },
                    icon: const Icon(Icons.shield_outlined),
                    label: Text(s.jobWarrantyClaim),
                  ),
                if (j.canCancel)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(s.jobCancelConfirm, style: ctx.text.titleLarge),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: TextButton.styleFrom(foregroundColor: ctx.colors.danger),
                                    child: Text(s.jobCancel),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) await _run(() => repo.cancelJob(widget.orderId, j.id, null), s.jobCancelDone);
                          },
                    style: TextButton.styleFrom(foregroundColor: c.danger),
                    child: Text(s.jobCancel),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _date(DateTime d) => '${_two(d.day)}.${_two(d.month)}.${d.year}';

(String, Color) _jobStatus(S s, AppColors c, String st) => switch (st) {
      'pending' => (s.jobPending, _amber),
      'assigned' => (s.jobAssigned, Brand.link),
      'accepted' => (s.jobAccepted, Brand.link),
      'on_the_way' => (s.jobOnTheWay, Brand.link),
      'arrived' => (s.jobArrived, _amber),
      'in_progress' => (s.jobInProgress, _amber),
      'completed' => (s.jobCompleted, c.success),
      'failed' => (s.jobFailed, c.danger),
      'cancelled' => (s.jobCancelled, c.textSecondary),
      _ => (st, c.textSecondary),
    };

class _PriceApproval extends StatelessWidget {
  const _PriceApproval({required this.job, required this.busy, required this.onAccept, required this.onReject});
  final TrackJob job;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: _amber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.jobPriceTitle, style: context.text.titleMedium),
          const SizedBox(height: 4),
          Text(sumText(context, job.finalAmount!), style: context.text.headlineSmall),
          if (job.quoted != null) Text(s.jobPriceWas(sumText(context, job.quoted!)), style: context.text.bodySmall),
          if (job.finalComment != null) ...[
            const SizedBox(height: 6),
            Text('«${job.finalComment}»', style: context.text.bodyMedium?.copyWith(color: c.textPrimary)),
          ],
          if (job.visitFee != null) ...[
            const SizedBox(height: 6),
            Text(s.jobPriceRejectNote(sumText(context, job.visitFee!)), style: context.text.bodySmall),
          ],
          const SizedBox(height: Space.md),
          Row(
            children: [
              Expanded(child: FilledButton(onPressed: busy ? null : onAccept, child: Text(s.jobPriceAccept))),
              const SizedBox(width: Space.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onReject,
                  style: OutlinedButton.styleFrom(foregroundColor: c.danger),
                  child: Text(s.jobPriceReject),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Isbot kodi — katta, o'qilishi oson raqamlar.
class _ProofCode extends StatelessWidget {
  const _ProofCode({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0A3A73), Brand.navy]),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.jobCode, style: context.text.bodySmall?.copyWith(color: Colors.white70)),
                const SizedBox(height: 2),
                Text(s.jobCodeHint, style: context.text.bodySmall?.copyWith(color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            code.split('').join(' '),
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 2),
          ),
        ],
      ),
    );
  }
}

class _RateSheet extends StatefulWidget {
  const _RateSheet();
  @override
  State<_RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<_RateSheet> {
  int _stars = 5;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.lg + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(s.jobRate, style: context.text.titleLarge),
          const SizedBox(height: Space.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  iconSize: 40,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _stars = i);
                  },
                  icon: Icon(i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded, color: _amber),
                ),
            ],
          ),
          const SizedBox(height: Space.sm),
          TextField(controller: _ctrl, maxLines: 3, maxLength: 1000, decoration: InputDecoration(hintText: s.jobRateHint)),
          const SizedBox(height: Space.sm),
          FilledButton(
            onPressed: () => Navigator.pop(context, (_stars, _ctrl.text)),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: Text(s.jobRateSend),
          ),
        ],
      ),
    );
  }
}

/* ───────────────────────── Umumiy bo'laklar ───────────────────────── */

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: Space.md),
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: c.border),
      ),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: context.text.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.trailing, this.color});
  final IconData icon;
  final String text;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 19, color: color ?? c.textSecondary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: context.text.bodyMedium?.copyWith(color: color ?? c.textPrimary))),
        ?trailing,
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(Radii.md)),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: context.text.bodyMedium?.copyWith(color: context.colors.textPrimary))),
          ],
        ),
      );
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.icon, required this.title, required this.subtitle, this.phone});
  final IconData icon;
  final String title;
  final String subtitle;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Row(
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: c.surfaceMuted,
          child: Text(title.isEmpty ? '?' : title.characters.first.toUpperCase(),
              style: context.text.titleMedium?.copyWith(color: c.textPrimary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleMedium),
              Text(subtitle, style: context.text.bodySmall),
            ],
          ),
        ),
        if (phone != null)
          IconButton.filledTonal(
            tooltip: s.trackCall,
            onPressed: () => launchUrl(Uri.parse('tel:$phone')),
            icon: const Icon(Icons.call_rounded),
          ),
      ],
    );
  }
}
