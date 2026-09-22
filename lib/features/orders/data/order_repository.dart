import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import 'order_models.dart';

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
  });

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

/// Buyurtma qatori — backendga shu ko'rinishda ketadi (narxni server hisoblaydi).
class OrderLine {
  const OrderLine({
    required this.productId,
    required this.modelTitle,
    required this.qty,
    this.modelId,
    this.variantId,
  });
  final int productId;
  final String modelTitle;
  final int qty;
  final int? modelId;
  final int? variantId;
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
      'items': [
        for (final l in lines)
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
  Future<void> issueQuote(int orderId) => _api.post('/orders/$orderId/quote/issue', const {});

  Future<void> requestAgain(int orderId) => _api.post('/orders/$orderId/quote/request-again', const {});

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
