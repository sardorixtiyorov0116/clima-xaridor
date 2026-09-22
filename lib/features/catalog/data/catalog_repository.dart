import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import 'models.dart';

class CatalogRepository {
  CatalogRepository(this._api);

  final ApiClient _api;
  final _plain = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    responseType: ResponseType.plain,
  ));

  static List<Map<String, dynamic>> _list(Map<String, dynamic> r) {
    final d = r['data'] ?? r['rows'] ?? r['items'];
    return [for (final e in (d is List ? d : const [])) if (e is Map<String, dynamic>) e];
  }

  Future<List<Category>> categories() async =>
      _list(await _api.getPublic('/category/all')).map(Category.fromJson).toList();

  /// Katalog kichik (~140 mahsulot) — `view=card` bilan hammasini bir so'rovda olamiz,
  /// qidiruv, saralash va filtr qurilmada ishlaydi.
  Future<List<Product>> products() async {
    final r = await _api.getPublic('/products/all?page=1&limit=500&view=card');
    return _list(r).map(Product.fromJson).where((p) => p.id > 0).toList();
  }

  Future<Product> product(int id) async {
    final r = await _api.getPublic('/products/one/$id');
    final m = r['data'] is Map<String, dynamic> ? r['data'] as Map<String, dynamic> : r;
    return Product.fromJson(m);
  }

  Future<List<PromoBanner>> banners() async {
    final list = _list(await _api.getPublic('/banners/all')).map(PromoBanner.fromJson).whereType<PromoBanner>().toList();
    return list;
  }

  Future<UsdRate> usdRate() async {
    final r = await _api.getPublic('/settings/usd-rate');
    final v = r['rate'];
    final rate = v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    if (rate <= 0) throw ApiException(ApiErrorKind.unknown);
    return UsdRate(rate);
  }

  /// R2 dagi tavsif: JSON satr ichida HTML (`"<p>…</p>"`). Bo'sh bo'lsa null.
  Future<String?> html(String url) async {
    final r = await _plain.get<String>(url);
    var body = (r.data ?? '').trim();
    if (body.startsWith('"')) {
      try {
        body = jsonDecode(body) as String;
      } catch (_) {}
    }
    final text = body.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    return text.isEmpty ? null : body;
  }
}
