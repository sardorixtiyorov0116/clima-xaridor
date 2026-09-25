/// Buyurtmani kuzatish (backend №38 va №39): `GET /orders/:id/tracking`.
/// Maxfiylik backendda: joylashuv faqat yo'lda, kuryer/usta faqat ismi bilan.
library;

import '../../catalog/data/models.dart';

String _s(Object? v) => v == null || '$v' == 'null' ? '' : '$v'.trim();
String? _t(Object? v) => _s(v).isEmpty ? null : _s(v);
int _i(Object? v) => v is int ? v : int.tryParse('$v') ?? 0;
int? _som(Object? v) {
  final d = double.tryParse('$v');
  return d == null || d <= 0 ? null : d.round();
}

DateTime? _date(Object? v) => DateTime.tryParse(_s(v))?.toLocal();

List<Map<String, dynamic>> _maps(Object? v) =>
    [for (final e in (v is List ? v : const [])) if (e is Map) Map<String, dynamic>.from(e)];

Map<String, dynamic>? _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : null;

class GeoPoint {
  const GeoPoint(this.lat, this.lng);
  final double lat;
  final double lng;

  static GeoPoint? from(Object? v) {
    final m = _map(v);
    if (m == null) return null;
    final a = double.tryParse('${m['lat']}');
    final b = double.tryParse('${m['lng']}');
    return a == null || b == null ? null : GeoPoint(a, b);
  }
}

class TrackStep {
  const TrackStep(this.key, this.at);
  final String key;
  final DateTime? at;
}

List<TrackStep> _steps(Object? v, String keyField) =>
    [for (final m in _maps(v)) TrackStep(_s(m[keyField]), _date(m['at']))];

class LiveLocation {
  const LiveLocation({required this.point, this.at, this.stale = false, this.heading});
  final GeoPoint point;
  final DateTime? at;
  final bool stale;
  final double? heading;

  static LiveLocation? from(Object? v) {
    final p = GeoPoint.from(v);
    if (p == null) return null;
    final m = _map(v)!;
    return LiveLocation(
      point: p,
      at: _date(m['at']),
      stale: m['stale'] == true,
      heading: double.tryParse('${m['heading']}'),
    );
  }
}

class TrackDelivery {
  const TrackDelivery({
    required this.id,
    required this.status,
    required this.steps,
    this.courierName,
    this.vehicleType,
    this.vehicleText,
    this.courierPhone,
    this.location,
    this.destination,
    this.destinationAddress,
    this.eta,
    this.cod,
    this.deliveredAt,
  });

  final int id;
  final String status;
  final List<TrackStep> steps;
  final String? courierName;
  final String? vehicleType;

  /// "Cobalt, oq, 01 A 123 BC" — bo'lsa.
  final String? vehicleText;
  final String? courierPhone;
  final LiveLocation? location;
  final GeoPoint? destination;
  final String? destinationAddress;
  final int? eta;
  final int? cod;
  final DateTime? deliveredAt;

  bool get onTheWay => status == 'on_the_way' || status == 'picked_up';

  factory TrackDelivery.fromJson(Map<String, dynamic> j) {
    final c = _map(j['courier']) ?? const {};
    final v = _map(c['vehicle']);
    final dest = _map(j['destination']);
    return TrackDelivery(
      id: _i(j['id']),
      status: _s(j['status']),
      steps: _steps(j['steps'], 'status'),
      courierName: _t(c['first_name']),
      vehicleType: _t(c['vehicle_type']),
      vehicleText: v == null ? null : [_t(v['model']), _t(v['color']), _t(v['plate'])].whereType<String>().join(', '),
      courierPhone: _t(c['phone']),
      location: LiveLocation.from(j['courier_location']),
      destination: GeoPoint.from(dest),
      destinationAddress: dest == null ? null : _t(dest['address']),
      eta: j['eta_minutes'] == null ? null : _i(j['eta_minutes']),
      cod: _som(j['cod_amount']),
      deliveredAt: _date(j['delivered_at']),
    );
  }
}

class TrackJobService {
  const TrackJobService({required this.name, required this.variant, required this.qty, required this.priceType});
  final L10nText name;
  final L10nText variant;
  final int qty;
  final String priceType;
}

class TrackJob {
  const TrackJob({
    required this.id,
    required this.status,
    required this.services,
    this.isWarranty = false,
    this.from,
    this.to,
    this.scheduleStatus,
    this.workerName,
    this.workerPhone,
    this.location,
    this.eta,
    this.proofCode,
    this.quoted,
    this.finalAmount,
    this.finalStatus,
    this.finalComment,
    this.visitFee,
    this.cod,
    this.photosAfter = const [],
    this.warrantyUntil,
    this.reviewRating,
    this.reviewComment,
    this.canReview = false,
  });

  final int id;
  final String status;
  final bool isWarranty;
  final List<TrackJobService> services;
  final DateTime? from;
  final DateTime? to;

  /// `proposed` · `confirmed` · `rescheduled`.
  final String? scheduleStatus;
  final String? workerName;
  final String? workerPhone;
  final LiveLocation? location;
  final int? eta;
  final String? proofCode;
  final int? quoted;
  final int? finalAmount;

  /// `pending` · `accepted` · `rejected`.
  final String? finalStatus;
  final String? finalComment;
  final int? visitFee;
  final int? cod;
  final List<String> photosAfter;
  final DateTime? warrantyUntil;
  final int? reviewRating;
  final String? reviewComment;
  final bool canReview;

  bool get active => const {'pending', 'assigned', 'accepted', 'on_the_way', 'arrived', 'in_progress'}.contains(status);
  bool get canCancel => const {'pending', 'assigned', 'accepted'}.contains(status);
  bool get pricePending => finalStatus == 'pending';
  bool get needsScheduleAnswer => scheduleStatus == 'rescheduled';
  bool get warrantyOpen => status == 'completed' && warrantyUntil != null && warrantyUntil!.isAfter(DateTime.now());

  factory TrackJob.fromJson(Map<String, dynamic> j) {
    final sch = _map(j['scheduled']) ?? const {};
    final w = _map(j['worker']) ?? const {};
    final p = _map(j['price']) ?? const {};
    final r = _map(j['review']);
    return TrackJob(
      id: _i(j['id']),
      status: _s(j['status']),
      isWarranty: j['is_warranty'] == true,
      services: [
        for (final m in _maps(j['services']))
          TrackJobService(
            name: L10nText(_s(m['name']), _s(m['name_ru']), _s(m['name_en'])),
            variant: L10nText(_s(m['variant']), _s(m['variant_ru']), _s(m['variant_en'])),
            qty: _i(m['quantity']).clamp(1, 999),
            priceType: _s(m['price_type']),
          ),
      ],
      from: _date(sch['from']),
      to: _date(sch['to']),
      scheduleStatus: _t(sch['status']),
      workerName: _t(w['first_name']),
      workerPhone: _t(w['phone']),
      location: LiveLocation.from(j['worker_location']),
      eta: j['eta_minutes'] == null ? null : _i(j['eta_minutes']),
      proofCode: _t(j['proof_code']),
      quoted: _som(p['quoted']),
      finalAmount: _som(p['final']),
      finalStatus: _t(p['final_status']),
      finalComment: _t(p['final_comment']),
      visitFee: _som(p['visit_fee']),
      cod: _som(j['cod_amount']),
      photosAfter: [for (final u in (j['photos_after'] is List ? j['photos_after'] as List : const [])) if (_s(u).isNotEmpty) _s(u)],
      warrantyUntil: _date(j['warranty_until']),
      reviewRating: r == null ? null : _i(r['rating']),
      reviewComment: r == null ? null : _t(r['comment']),
      canReview: j['can_review'] == true,
    );
  }
}

class TrackItem {
  const TrackItem({required this.name, required this.model, required this.qty});
  final String name;
  final String model;
  final int qty;
}

class TrackPart {
  const TrackPart({
    required this.storeId,
    required this.storeName,
    required this.items,
    required this.jobs,
    this.storePhone,
    this.stage,
    this.delivery,
  });
  final int storeId;
  final String storeName;
  final String? storePhone;

  /// `waiting` · `packing` · `ready`; faqat xizmat sotgan hamkorda `null`.
  final String? stage;
  final List<TrackItem> items;
  final TrackDelivery? delivery;
  final List<TrackJob> jobs;

  factory TrackPart.fromJson(Map<String, dynamic> j) {
    final st = _map(j['store']) ?? const {};
    final d = _map(j['delivery']);
    return TrackPart(
      storeId: _i(st['id']),
      storeName: _s(st['name']),
      storePhone: _t(st['phone']),
      stage: _t(j['stage']),
      items: [
        for (final m in _maps(j['items']))
          TrackItem(name: _s(m['name']), model: _s(m['model']), qty: _i(m['quantity']).clamp(1, 99999)),
      ],
      delivery: d == null ? null : TrackDelivery.fromJson(d),
      jobs: _maps(j['jobs']).map(TrackJob.fromJson).toList(),
    );
  }
}

class OrderTracking {
  const OrderTracking({required this.orderId, required this.status, required this.steps, required this.parts});
  final int orderId;
  final String status;
  final List<TrackStep> steps;
  final List<TrackPart> parts;

  Iterable<TrackDelivery> get deliveries => parts.map((p) => p.delivery).whereType<TrackDelivery>();
  Iterable<TrackJob> get jobs => parts.expand((p) => p.jobs);

  /// Jonli joylashuv bor — ekran 15 soniyada yangilanadi.
  bool get live =>
      deliveries.any((d) => d.onTheWay) || jobs.any((j) => j.status == 'on_the_way' || j.status == 'arrived');

  factory OrderTracking.fromJson(Map<String, dynamic> j) => OrderTracking(
        orderId: _i(j['order_id']),
        status: _s(j['status']),
        steps: _steps(j['steps'], 'key'),
        parts: _maps(j['parts']).map(TrackPart.fromJson).toList(),
      );
}
