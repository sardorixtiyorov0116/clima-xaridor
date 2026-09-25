/// Katalog modellari. Backend narxlari AQSh dollarida — so'mga [UsdRate] bilan o'giriladi
/// (sayt ham shunday qiladi: 3 060 × 11 839,59 = 36 229 145 so'm).
library;

String _s(Object? v) => v == null ? '' : v.toString().trim();
double? _d(Object? v) {
  if (v == null) return null;
  final n = v is num ? v.toDouble() : double.tryParse(v.toString());
  return (n == null || n <= 0) ? null : n;
}

int _i(Object? v) => v is int ? v : int.tryParse('$v') ?? 0;

/// Uch tilli matn: tanlangan tilda bo'lmasa — boshqasidan.
class L10nText {
  const L10nText(this.uz, this.ru, this.en);
  final String uz;
  final String ru;
  final String en;

  factory L10nText.from(Map<String, dynamic> j, String key) =>
      L10nText(_s(j['${key}_uz']), _s(j['${key}_ru']), _s(j['${key}_en']));

  String of(String lang) {
    final first = switch (lang) { 'ru' => ru, 'en' => en, _ => uz };
    if (first.isNotEmpty) return first;
    return [uz, ru, en].firstWhere((s) => s.isNotEmpty, orElse: () => '');
  }

  bool matches(String q) =>
      uz.toLowerCase().contains(q) || ru.toLowerCase().contains(q) || en.toLowerCase().contains(q);
}

class Category {
  const Category({required this.id, required this.parentId, required this.name});
  final int id;
  final int? parentId;
  final L10nText name;

  factory Category.fromJson(Map<String, dynamic> j) {
    final id = _i(j['id']);
    final p = j['category_id'];
    // Bazada ba'zi kategoriyalar o'zini o'ziga ota qilib qo'ygan (34, 35) — ildiz deb olamiz.
    final parent = p == null || _i(p) == id ? null : _i(p);
    return Category(id: id, parentId: parent, name: L10nText.from(j, 'name'));
  }
}

class Store {
  const Store({
    required this.id,
    required this.name,
    this.logoUrl,
    this.phone,
    this.telegram,
    this.address,
    this.description,
    this.legalName,
    this.tin,
    this.email,
    this.website,
  });
  final int id;
  final String name;
  final String? legalName;
  final String? tin;
  final String? email;
  final String? website;
  final String? logoUrl;
  final String? phone;
  final String? telegram;
  final String? address;
  final L10nText? description;

  static Store? fromJson(Object? o) {
    if (o is! Map<String, dynamic>) return null;
    String? n(String k) => _s(o[k]).isEmpty ? null : _s(o[k]);
    return Store(
      id: _i(o['id']),
      name: _s(o['name']),
      logoUrl: n('logo_url'),
      phone: n('phone'),
      telegram: n('telegram'),
      address: n('address'),
      description: L10nText.from(o, 'description'),
      legalName: n('legal_name'),
      tin: n('tin'),
      email: n('email'),
      website: n('website'),
    );
  }
}

/// Narx va aksiya. Aksiya muddati o'tgan bo'lsa hisobga olinmaydi.
///
/// [usd] DOIM dollarda — so'mda narx qo'ygan do'konda ham (backend №37: `price_uzs / kurs`),
/// shuning uchun taqqoslash va saralash shu bilan. Ko'rsatish esa [uzs] bilan: so'mdagi
/// narx aynan sotuvchi yozgani, dollardagisi backend kursida hisoblangani.
class Price {
  const Price(this.usd, {this.saleUsd, this.uzs, this.saleUzs});
  final double usd;
  final double? saleUsd;

  /// So'mdagi tayyor narx (`price_uzs`, `sale_price_uzs`). Eski backend — null.
  final int? uzs;
  final int? saleUzs;

  double get effective => saleUsd ?? usd;
  bool get onSale => saleUsd != null && saleUsd! < usd;

  /// Asosiy va amaldagi narx so'mda: backenddagi aniq qiymat, bo'lmasa kurs bilan.
  int? baseSum(UsdRate? rate) => uzs ?? rate?.toSum(usd);
  int? effectiveSum(UsdRate? rate) => saleUsd != null ? (saleUzs ?? rate?.toSum(saleUsd!)) : baseSum(rate);

  static Price? parse(Object? price, Object? sale, Object? saleEnds, {Object? uzs, Object? saleUzs}) {
    final p = _d(price);
    if (p == null) return null;
    var s = _d(sale);
    final ends = DateTime.tryParse(_s(saleEnds));
    if (ends != null && ends.isBefore(DateTime.now())) s = null;
    return Price(p, saleUsd: s, uzs: _d(uzs)?.round(), saleUzs: s == null ? null : _d(saleUzs)?.round());
  }
}

/// SAP varianti (model ichidagi aniq artikul).
class Variant {
  const Variant({required this.id, required this.code, required this.name, this.price});
  final int id;
  final String code;
  final String name;
  final Price? price;

  factory Variant.fromJson(Map<String, dynamic> j) => Variant(
        id: _i(j['id']),
        code: _s(j['sap_name']),
        name: _s(j['in_model_name']),
        price: Price.parse(j['price'], j['sale_price'], j['sale_ends_at'], uzs: j['price_uzs'], saleUzs: j['sale_price_uzs']),
      );
}

/// Mahsulot modeli (backendda `characters`).
class ProductModel {
  const ProductModel({
    required this.id,
    required this.title,
    this.price,
    this.variants = const [],
    this.specsUrl,
    this.airflow,
    this.pressure,
  });
  final int id;
  final String title;
  final Price? price;
  final List<Variant> variants;

  /// R2 dagi "Технические характеристики" jadvali (faqat to'liq javobda).
  final String? specsUrl;
  final double? airflow; // m³/soat
  final double? pressure; // Pa

  /// Narx: variantlar bo'lsa — eng arzon variant, bo'lmasa model narxi.
  Price? get fromPrice {
    final priced = variants.map((v) => v.price).whereType<Price>().toList()
      ..sort((a, b) => a.effective.compareTo(b.effective));
    return priced.isNotEmpty && price == null ? priced.first : price;
  }

  factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
        id: _i(j['id']),
        title: _s(j['title']),
        price: Price.parse(j['price'], j['sale_price'], j['sale_ends_at'], uzs: j['price_uzs'], saleUzs: j['sale_price_uzs']),
        specsUrl: _s(j['content']).startsWith('http') ? _s(j['content']) : null,
        airflow: _d(j['airflow_m3h']),
        pressure: _d(j['pressure_pa']),
        variants: [
          for (final v in (j['insides'] as List? ?? const []))
            if (v is Map<String, dynamic>) Variant.fromJson(v),
        ],
      );
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.images,
    required this.models,
    required this.createdAt,
    this.store,
    this.producer,
    this.minUsd,
    this.minSaleUsd,
    this.minUzs,
    this.minSaleUzs,
    this.views = 0,
    this.shortDescription,
    this.descriptionUrl,
    this.purposeUrl,
    this.sizesUrl,
    this.markingUrl,
  });

  final int id;
  final L10nText name;
  final int categoryId;
  final List<String> images;
  final List<ProductModel> models;
  final DateTime createdAt;
  final Store? store;
  final String? producer;
  final double? minUsd;
  final double? minSaleUsd;

  /// "...dan" narx so'mda (№37 `min_price_uzs`) — so'mdagi mahsulotda kursga ko'paytirilmaydi.
  final int? minUzs;
  final int? minSaleUzs;
  final int views;
  final L10nText? shortDescription;

  /// R2 dagi HTML (JSON satr ko'rinishida) — tavsif va qo'llanilishi.
  final String? descriptionUrl;
  final String? purposeUrl;

  /// O'lchamlar jadvali va belgilanish sxemasi (HTML).
  final String? sizesUrl;
  final String? markingUrl;

  /// Bitta tugma bilan savatga qo'shsa bo'ladimi (model/variant tanlash shart emas).
  bool get quickAddable =>
      models.isEmpty || (models.length == 1 && models.first.variants.length <= 1);

  bool get hasPrice => minUsd != null;
  bool get onSale => minSaleUsd != null && minUsd != null && minSaleUsd! < minUsd!;
  bool get multiModel => models.length > 1;
  String? get cover => images.isEmpty ? null : images.first;

  factory Product.fromJson(Map<String, dynamic> j) {
    String? url(String k) => _s(j[k]).startsWith('http') ? _s(j[k]) : null;
    final models = [
      for (final m in (j['characters'] as List? ?? const []))
        if (m is Map<String, dynamic>) ProductModel.fromJson(m),
    ]..sort((a, b) =>
        (a.fromPrice?.effective ?? double.infinity).compareTo(b.fromPrice?.effective ?? double.infinity));
    return Product(
      id: _i(j['id']),
      name: L10nText.from(j, 'name'),
      categoryId: _i(j['category_id']),
      images: [
        for (final im in (j['images'] as List? ?? const []))
          if (im is Map && _s(im['image_link']).startsWith('http')) _s(im['image_link']),
      ],
      models: models,
      createdAt: DateTime.tryParse(_s(j['createdAt'])) ?? DateTime(2024),
      store: Store.fromJson(j['store']),
      producer: _s(j['producer']).isEmpty ? null : _s(j['producer']),
      minUsd: _d(j['min_price']),
      minSaleUsd: _d(j['min_sale_price']),
      minUzs: _d(j['min_price_uzs'])?.round(),
      minSaleUzs: _d(j['min_sale_price_uzs'])?.round(),
      views: _i(j['views']),
      shortDescription: j.containsKey('description_short_uz') ? L10nText.from(j, 'description_short') : null,
      descriptionUrl: url('opisaniya'),
      purposeUrl: url('naznacheniya'),
      sizesUrl: url('sizes'),
      markingUrl: url('markirovka'),
    );
  }

  /// Qidiruv: nomi (3 til), model va SAP kodlari, ishlab chiqaruvchi.
  bool matches(String q) {
    if (name.matches(q)) return true;
    if ((producer ?? '').toLowerCase().contains(q)) return true;
    for (final m in models) {
      if (m.title.toLowerCase().contains(q)) return true;
      for (final v in m.variants) {
        if (v.code.toLowerCase().contains(q) || v.name.toLowerCase().contains(q)) return true;
      }
    }
    return false;
  }
}

class PromoBanner {
  const PromoBanner({required this.id, required this.image, required this.title, required this.text, this.productId, this.link});
  final int id;
  final String image;
  final L10nText title;
  final L10nText text;
  final int? productId;
  final String? link;

  static PromoBanner? fromJson(Map<String, dynamic> j) {
    if (j['is_active'] == false || !_s(j['img_url']).startsWith('http')) return null;
    return PromoBanner(
      id: _i(j['id']),
      image: _s(j['img_url']),
      title: L10nText.from(j, 'title'),
      text: L10nText.from(j, 'text'),
      productId: j['product_id'] == null ? null : _i(j['product_id']),
      link: _s(j['link']).startsWith('http') ? _s(j['link']) : null,
    );
  }
}

/// Dollar kursi (so'm). Backend `GET /settings/usd-rate`.
class UsdRate {
  const UsdRate(this.rate);
  final double rate;

  int toSum(double usd) => (usd * rate).round();
}
