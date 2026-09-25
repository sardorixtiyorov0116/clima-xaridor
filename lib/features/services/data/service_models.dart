/// Xizmatlar (backend №39): o'rnatish, tozalash, ta'mir. Xizmatni hamkor sotadi —
/// do'kon ham, faqat xizmat ko'rsatuvchi ham. Narx faqat so'mda.
library;

import 'package:flutter/material.dart';

import '../../catalog/data/models.dart';

String _s(Object? v) => v == null || '$v' == 'null' ? '' : '$v'.trim();
int _i(Object? v) => v is int ? v : int.tryParse('$v') ?? 0;
int? _som(Object? v) {
  final d = double.tryParse('$v');
  return d == null || d <= 0 ? null : d.round();
}

double? _d(Object? v) => double.tryParse('$v');

List<Map<String, dynamic>> _maps(Object? v) =>
    [for (final e in (v is List ? v : const [])) if (e is Map) Map<String, dynamic>.from(e)];

class ServiceCategory {
  const ServiceCategory({required this.id, required this.key, required this.name});
  final int id;
  final String key;
  final L10nText name;

  factory ServiceCategory.fromJson(Map<String, dynamic> j) =>
      ServiceCategory(id: _i(j['id']), key: _s(j['key']), name: L10nText.from(j, 'name'));

  IconData get icon => serviceIcon(key);
}

/// Xizmat turining belgisi — backenddagi Material nomlariga mos.
IconData serviceIcon(String key) => switch (key) {
      'installation' => Icons.build_rounded,
      'dismantling' => Icons.handyman_rounded,
      'cleaning' => Icons.cleaning_services_rounded,
      'refill' => Icons.ac_unit_rounded,
      'repair' => Icons.construction_rounded,
      'survey' => Icons.straighten_rounded,
      _ => Icons.home_repair_service_rounded,
    };

class ServiceVariant {
  const ServiceVariant({required this.id, required this.name, this.price});
  final int id;
  final L10nText name;

  /// So'mda. `null` — narx KP orqali.
  final int? price;

  factory ServiceVariant.fromJson(Map<String, dynamic> j) =>
      ServiceVariant(id: _i(j['id']), name: L10nText.from(j, 'name'), price: _som(j['price_uzs']));
}

class ServicePartner {
  const ServicePartner({
    required this.id,
    required this.name,
    this.logo,
    this.rating,
    this.reviews = 0,
    this.jobsDone = 0,
  });
  final int id;
  final String name;
  final String? logo;
  final double? rating;
  final int reviews;
  final int jobsDone;

  factory ServicePartner.fromJson(Map<String, dynamic> j) => ServicePartner(
        id: _i(j['id']),
        name: _s(j['name']),
        logo: _s(j['logo'] ?? j['logo_url']).isEmpty ? null : _s(j['logo'] ?? j['logo_url']),
        rating: _d(j['rating'] ?? j['service_rating']),
        reviews: _i(j['reviews_count'] ?? j['service_reviews_count']),
        jobsDone: _i(j['jobs_done']),
      );
}

class ServiceOffer {
  const ServiceOffer({
    required this.id,
    required this.storeId,
    required this.name,
    required this.description,
    required this.priceType,
    required this.unit,
    required this.variants,
    this.category,
    this.visitFee,
    this.duration,
    this.warrantyMonths = 0,
    this.photos = const [],
    this.minPrice,
    this.provider,
    this.recommended = false,
    this.suggestedVariantId,
  });

  final int id;
  final int storeId;
  final ServiceCategory? category;
  final L10nText name;
  final L10nText description;

  /// `fixed` · `from` · `quote`.
  final String priceType;
  final String unit;
  final int? visitFee;
  final int? duration;
  final int warrantyMonths;
  final List<String> photos;
  final List<ServiceVariant> variants;
  final int? minPrice;
  final ServicePartner? provider;

  /// Shu tovarni sotayotgan do'konning o'z xizmati (`products/:id/services`).
  final bool recommended;
  final int? suggestedVariantId;

  bool get isQuote => priceType == 'quote';
  bool get isFrom => priceType == 'from';

  int? get fromPrice {
    if (minPrice != null) return minPrice;
    final p = variants.map((v) => v.price).whereType<int>().toList();
    return p.isEmpty ? null : p.reduce((a, b) => a < b ? a : b);
  }

  ServiceVariant? get suggestedVariant =>
      variants.where((v) => v.id == suggestedVariantId).firstOrNull ?? (variants.length == 1 ? variants.first : null);

  factory ServiceOffer.fromJson(Map<String, dynamic> j) {
    final cat = j['category'];
    final st = j['store'];
    return ServiceOffer(
      id: _i(j['id']),
      storeId: _i(j['store_id'] ?? (st is Map ? st['id'] : null)),
      category: cat is Map ? ServiceCategory.fromJson(Map<String, dynamic>.from(cat)) : null,
      name: L10nText.from(j, 'name'),
      description: L10nText.from(j, 'description'),
      priceType: _s(j['price_type']).isEmpty ? 'fixed' : _s(j['price_type']),
      unit: _s(j['unit']),
      visitFee: _som(j['visit_fee_uzs']),
      duration: j['duration_minutes'] == null ? null : _i(j['duration_minutes']),
      warrantyMonths: _i(j['warranty_months']),
      photos: [for (final p in (j['photos'] is List ? j['photos'] as List : const [])) if (_s(p).isNotEmpty) _s(p)],
      variants: _maps(j['variants']).map(ServiceVariant.fromJson).where((v) => v.id > 0).toList(),
      minPrice: _som(j['min_price_uzs']),
      provider: st is Map ? ServicePartner.fromJson(Map<String, dynamic>.from(st)) : null,
      recommended: j['recommended'] == true,
      suggestedVariantId: j['suggested_variant_id'] == null ? null : _i(j['suggested_variant_id']),
    );
  }
}

class District {
  const District({required this.code, required this.name});
  final String code;
  final L10nText name;
}

class Region {
  const Region({required this.code, required this.name, required this.districts});
  final String code;
  final L10nText name;
  final List<District> districts;

  factory Region.fromJson(Map<String, dynamic> j) => Region(
        code: _s(j['code']),
        name: L10nText.from(j, 'name'),
        districts: [
          for (final d in _maps(j['districts'])) District(code: _s(d['code']), name: L10nText.from(d, 'name')),
        ],
      );
}

/// Mijozning xizmat manzili hududi — qidiruv va buyurtma uchun.
class ServiceArea {
  const ServiceArea({required this.region, this.district});
  final String region;
  final String? district;

  String toStorage() => district == null ? region : '$region/$district';

  static ServiceArea? fromStorage(String? v) {
    if (v == null || v.isEmpty) return null;
    final p = v.split('/');
    return ServiceArea(region: p.first, district: p.length > 1 && p[1].isNotEmpty ? p[1] : null);
  }
}
