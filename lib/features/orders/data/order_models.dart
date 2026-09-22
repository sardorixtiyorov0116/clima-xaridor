/// Buyurtma va KP (xaridor ko'radigan qismi). Backend javoblari (`orders/oneuser`,
/// `orders/create`) turlicha kalit ishlatadi — maydonlar ehtiyotkorlik bilan o'qiladi.
library;

String _s(Object? v) => v == null || '$v' == 'null' ? '' : '$v'.trim();
int _i(Object? v) => int.tryParse('$v') ?? 0;
double? _money(Object? v) {
  final d = double.tryParse('$v');
  return d == null || d <= 0 ? null : d;
}

DateTime? _date(Object? v) => DateTime.tryParse(_s(v))?.toLocal();

List<Map<String, dynamic>> _maps(Object? v) =>
    [for (final e in (v is List ? v : const [])) if (e is Map<String, dynamic>) e];

class OrderItem {
  const OrderItem({required this.id, required this.productId, required this.model, required this.qty, this.price});
  final int id;
  final int productId;
  final String model;
  final int qty;

  /// Bir dona narxi, so'mda. null — narxini sotuvchi beradi.
  final double? price;

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        id: _i(j['id']),
        productId: _i(j['product_id']),
        model: _s(j['product_model']),
        qty: _i(j['quantity']).clamp(1, 99999),
        price: _money(j['price']),
      );
}

class QuoteItem {
  const QuoteItem({required this.orderItemId, required this.name, required this.model, required this.qty, this.price});
  final int orderItemId;
  final String name;
  final String model;
  final int qty;
  final double? price;

  double? get sum => price == null ? null : price! * qty;

  factory QuoteItem.fromJson(Map<String, dynamic> j) => QuoteItem(
        orderItemId: _i(j['order_item_id']),
        name: _s(j['name']),
        model: _s(j['model']),
        qty: _i(j['quantity']).clamp(1, 99999),
        price: _money(j['price']),
      );
}

/// Tijorat taklifi — bitta do'kon qatorlari uchun bitta versiya.
class Quote {
  const Quote({
    required this.version,
    required this.storeId,
    required this.items,
    this.validUntil,
    this.sentAt,
    this.deliveryTerms,
    this.paymentTerms,
    this.note,
  });
  final int version;
  final int storeId;
  final List<QuoteItem> items;
  final DateTime? validUntil;
  final DateTime? sentAt;
  final String? deliveryTerms;
  final String? paymentTerms;
  final String? note;

  bool get allPriced => items.isNotEmpty && items.every((i) => i.price != null);
  int get unpricedCount => items.where((i) => i.price == null).length;
  double get total => items.fold(0, (a, i) => a + (i.sum ?? 0));

  bool get expired {
    if (validUntil == null) return false;
    final now = DateTime.now();
    final end = DateTime(validUntil!.year, validUntil!.month, validUntil!.day, 23, 59, 59);
    return now.isAfter(end);
  }

  factory Quote.fromJson(Map<String, dynamic> j) {
    String? t(String k) => _s(j[k]).isEmpty ? null : _s(j[k]);
    return Quote(
      version: _i(j['version']),
      storeId: _i(j['store_id']),
      items: _maps(j['items']).map(QuoteItem.fromJson).toList(),
      validUntil: _date(j['valid_until']),
      sentAt: _date(j['sent_at'] ?? j['created_at']),
      deliveryTerms: t('delivery_terms'),
      paymentTerms: t('payment_terms'),
      note: t('note'),
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.status,
    required this.kind,
    required this.items,
    this.quotes = const [],
    this.total,
    this.createdAt,
    this.source,
    this.location,
    this.addressDetails,
    this.recipientName,
    this.recipientPhone,
    this.companyName,
    this.companyTin,
    this.comment,
    this.acceptedVersion,
  });
  final int id;
  final String status;
  final String kind;
  final List<OrderItem> items;
  final List<Quote> quotes;
  final double? total;
  final DateTime? createdAt;
  final String? source;
  final String? location;
  final String? addressDetails;
  final String? recipientName;
  final String? recipientPhone;
  final String? companyName;
  final String? companyTin;
  final String? comment;
  final int? acceptedVersion;

  bool get isQuote => kind == 'quote';
  bool get wasQuote => isQuote || acceptedVersion != null || quotes.isNotEmpty;

  /// Har do'kon uchun eng oxirgi KP versiyasi.
  List<Quote> get latestQuotes {
    final byStore = <int, Quote>{};
    for (final q in quotes) {
      final cur = byStore[q.storeId];
      if (cur == null || q.version > cur.version) byStore[q.storeId] = q;
    }
    return byStore.values.toList();
  }

  factory Order.fromJson(Map<String, dynamic> j) {
    String? t(String k) => _s(j[k]).isEmpty || _s(j[k]) == '—' ? null : _s(j[k]);
    return Order(
      id: _i(j['id']),
      status: _s(j['status']).isEmpty ? 'new' : _s(j['status']),
      kind: _s(j['kind']).isEmpty ? 'order' : _s(j['kind']),
      items: _maps(j['orderItems'] ?? j['order_items'] ?? j['items']).map(OrderItem.fromJson).toList(),
      quotes: _maps(j['quotes']).map(Quote.fromJson).toList(),
      total: _money(j['totalAmount'] ?? j['total_amount']),
      createdAt: _date(j['createdAt'] ?? j['created_at']),
      source: t('source'),
      location: t('location'),
      addressDetails: t('address_details'),
      recipientName: t('recipient_name'),
      recipientPhone: t('recipient_phone'),
      companyName: t('company_name'),
      companyTin: t('company_tin'),
      comment: t('comment'),
      acceptedVersion: j['quote_accepted_version'] == null ? null : _i(j['quote_accepted_version']),
    );
  }

  /// `orders/create` javobi: `{ newOrder, quotes, all_priced }` → bitta Order.
  static Order fromCreate(Map<String, dynamic> r) {
    final o = Map<String, dynamic>.from((r['newOrder'] ?? r['order'] ?? r) as Map);
    if (r['quotes'] is List && o['quotes'] == null) o['quotes'] = r['quotes'];
    return Order.fromJson(o);
  }
}
