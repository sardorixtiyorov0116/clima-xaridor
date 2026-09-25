import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import 'order_models.dart';
import 'tracking_models.dart';

/// Buyurtma uchun manzil va qabul qiluvchi.
class CheckoutForm {
  const CheckoutForm({
    required this.kind,
    required this.address,
    required this.recipientName,
    required this.recipientPhone,
    this.details,
    this.lat,
    this.lng,
    this.comment,
    this.companyName,
    this.companyTin,
    this.service,
  });

  /// Xizmat qatorlari bo'lsa (№39) — hudud va mijoz taklif qilgan vaqt.
  final ServiceVisit? service;

  /// `order` — sotib olish, `quote` — KP.
  final String kind;
  final String address;
  final String? details;
  final double? lat;
  final double? lng;
  final String recipientName;
  final String recipientPhone;
  final String? comment;
  final String? companyName;
  final String? companyTin;
}

/// Xizmat tashrifi (№39): hudud majburiy, vaqt — mijozning taklifi (hamkor tasdiqlaydi).
class ServiceVisit {
  const ServiceVisit({
    required this.regionCode,
    required this.districtCode,
    required this.date,
    required this.windowFrom,
    required this.windowTo,
    this.comment,
  });
  final String regionCode;
  final String? districtCode;
  final DateTime date;

  /// "10:00"
  final String windowFrom;
  final String windowTo;
  final String? comment;

  String get dateText =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Buyurtma qatori — backendga shu ko'rinishda ketadi (narxni server hisoblaydi).
/// Xizmat qatorida `productId` 0, `serviceId` bor; `forLineIndex` — shu so'rovdagi
/// qaysi tovar qatori uchun (o'rnatish).
class OrderLine {
  const OrderLine({
    required this.productId,
    required this.modelTitle,
    required this.qty,
    this.modelId,
    this.variantId,
  })  : serviceId = null,
        serviceVariantId = null,
        forLineIndex = null;

  const OrderLine.service({
    required int this.serviceId,
    required int this.serviceVariantId,
    required this.qty,
    this.forLineIndex,
  })  : productId = 0,
        modelTitle = '',
        modelId = null,
        variantId = null;

  final int productId;
  final String modelTitle;
  final int qty;
  final int? modelId;
  final int? variantId;
  final int? serviceId;
  final int? serviceVariantId;
  final int? forLineIndex;

  bool get isService => serviceId != null;
}

class OrderRepository {
  OrderRepository(this._api);
  final ApiClient _api;

  /// Bitta do'kon uchun buyurtma — buyurtma va qatorlar bitta so'rovda (backend №28).
  /// KP bo'lsa `source: site_kp` — narxli qatorlarga KP (v1) darhol qaytadi.
  Future<Order> create({required String userId, required CheckoutForm f, required List<OrderLine> lines}) async {
    String? clean(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();
    final r = await _api.post('/orders/create', {
      'user_id': int.tryParse(userId) ?? userId,
      'status': 'new',
      'kind': f.kind,
      if (f.kind == 'quote') 'source': 'site_kp',
      'location': clean(f.address) ?? '—',
      'address_details': ?clean(f.details),
      'lat': ?f.lat,
      'lng': ?f.lng,
      'recipient_name': clean(f.recipientName),
      'recipient_phone': clean(f.recipientPhone),
      'comment': ?clean(f.comment),
      'company_name': ?clean(f.companyName),
      'company_tin': ?clean(f.companyTin),
      if (f.service != null) ...{
        'region_code': f.service!.regionCode,
        'district_code': ?f.service!.districtCode,
        'service': {
          'preferred_date': f.service!.dateText,
          'window_from': f.service!.windowFrom,
          'window_to': f.service!.windowTo,
          'comment': ?clean(f.service!.comment),
        },
      },
      'items': [
        for (final l in lines)
          if (l.isService)
            {
              'service_id': l.serviceId,
              'variant_id': l.serviceVariantId,
              'quantity': l.qty,
              'for_item_index': ?l.forLineIndex,
            }
          else
            {
              'product_id': l.productId,
              'product_model': l.modelTitle,
              'product_model_id': ?l.modelId,
              'product_model_inside_id': ?l.variantId,
              'quantity': l.qty,
            },
      ],
    });
    final order = Order.fromCreate(r);
    if (order.id == 0) throw ApiException(ApiErrorKind.unknown);
    return order;
  }

  /// Xaridorning buyurtmalari (`GET /orders/oneuser/:userId`).
  Future<List<Order>> mine(String userId) async {
    final r = await _api.get('/orders/oneuser/$userId');
    final raw = r['data'] ?? r['orders'] ?? r['rows'];
    final list = raw is List ? raw : (r['id'] != null ? [r] : const []);
    return [for (final e in list) if (e is Map<String, dynamic>) Order.fromJson(e)];
  }

  Future<void> acceptQuote(int orderId, {required int version, String? company, String? tin}) =>
      _api.post('/orders/$orderId/quote/accept', {
        'version': version,
        if (company != null && company.isNotEmpty) 'company_name': company,
        if (tin != null && tin.isNotEmpty) 'company_tin': tin,
      });

  Future<void> rejectQuote(int orderId, String? reason) => _api.post('/orders/$orderId/quote/reject', {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });

  /// Qatorlari oldin qo'shilgan KP uchun hujjatni (v1) darhol chiqarish.

  Future<void> requestAgain(int orderId) => _api.post('/orders/$orderId/quote/request-again', const {});

  /* ── Kuzatish (№38) va ishlar (№39) ── */

  Future<OrderTracking> tracking(int orderId) async =>
      OrderTracking.fromJson(await _api.get('/orders/$orderId/tracking'));

  Future<void> answerSchedule(int orderId, int jobId, {required bool accept}) =>
      _api.post('/orders/$orderId/jobs/$jobId/schedule/${accept ? 'accept' : 'reject'}', const {});

  Future<void> answerPrice(int orderId, int jobId, {required bool accept}) =>
      _api.post('/orders/$orderId/jobs/$jobId/price/${accept ? 'accept' : 'reject'}', const {});

  Future<void> cancelJob(int orderId, int jobId, String? comment) => _api.post('/orders/$orderId/jobs/$jobId/cancel', {
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      });

  Future<void> reviewJob(int orderId, int jobId, int rating, String? comment) =>
      _api.post('/orders/$orderId/jobs/$jobId/review', {
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      });

  Future<void> warrantyClaim(int orderId, int jobId, String comment) =>
      _api.post('/orders/$orderId/jobs/$jobId/warranty-claim', {'comment': comment.trim(), 'photos': const <String>[]});

  /// OpenStreetMap Nominatim — nuqtadan manzil matni (bepul, kam so'rov uchun).
  Future<String?> reverseGeocode(double lat, double lng, String lang) async {
    try {
      final r = await Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
        headers: {'User-Agent': 'ClimaventApp/0.4 (climaventuz@outlook.com)'},
      )).get<Map<String, dynamic>>('https://nominatim.openstreetmap.org/reverse', queryParameters: {
        'format': 'jsonv2',
        'lat': lat,
        'lon': lng,
        'zoom': 18,
        'accept-language': lang,
      });
      final a = (r.data?['address'] as Map?) ?? const {};
      final parts = <String>[
        for (final k in ['city', 'town', 'county', 'suburb', 'neighbourhood', 'road', 'house_number'])
          if ((a[k] ?? '').toString().isNotEmpty) a[k].toString(),
      ];
      final uniq = <String>[];
      for (final p in parts) {
        if (!uniq.contains(p)) uniq.add(p);
      }
      final full = r.data == null ? null : r.data!['display_name']?.toString();
      return uniq.isEmpty ? full : uniq.join(', ');
    } catch (_) {
      return null;
    }
  }
}
