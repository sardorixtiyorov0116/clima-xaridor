import 'dart:io';

import 'package:climavent/features/catalog/data/models.dart';
import 'package:climavent/features/orders/data/order_models.dart';
import 'package:climavent/features/orders/ui/kp_pdf.dart';
import 'package:climavent/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Namunaviy KP → build/kp_sample*.pdf (ko'rib chiqish uchun). Internet kerak (shrift).
///
/// Qoida (egasi, 23.09.2026): blank har doim Climavent niki, tovar egasi «Yetkazib beruvchi»
/// qatorida; narxsiz qatorli do'kon bo'limi hujjatga umuman tushmaydi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const climavent = Store(
    id: 1,
    name: 'Climavent',
    address: 'Toshkent, Shota Rustaveli 115',
    phone: '+998 90 354 78 88',
    email: 'climaventuz@outlook.com',
    website: 'https://climavent.uz',
  );
  const jihozvent = Store(
    id: 2,
    name: 'Jihozvent',
    address: "Toshkent, Sirg'ali, Daryobo'yi MFY, Nilufar 3-tor ko'chasi, 77",
    phone: '+998 (78) 777 78 88',
    email: 'jihoz-vent@mail.ru',
    website: 'https://jihozvent.uz',
  );
  Store? storeOf(int id) => id == 1 ? climavent : jihozvent;

  Map<String, dynamic> head(int id) => {
        'id': id,
        'kind': 'quote',
        'status': 'quote_sent',
        'company_name': '"AIRCOOL" MChJ',
        'company_tin': '301234567',
        'recipient_name': 'Aziz Karimov',
        'recipient_phone': '+998901234567',
        'createdAt': '2026-09-21T10:00:00Z',
      };
  Map<String, dynamic> quote(int storeId, List<Map<String, dynamic>> items) => {
        'version': 1,
        'store_id': storeId,
        'valid_until': '2026-10-01',
        'sent_at': '2026-09-21T10:00:00Z',
        'items': items,
      };
  const priced = {
    'order_item_id': 1,
    'name': 'Kanalli ventilyator VKPP',
    'model': 'ВКПП 90х50-2D35',
    'quantity': 2,
    'price': 6855123,
  };
  const unpriced = {
    'order_item_id': 3,
    'name': 'Issiqlik almashtirgich ТСК',
    'model': 'ТСК',
    'quantity': 4,
    'price': null,
  };

  final s = lookupS(const Locale('uz'));

  test("narxli bo'lim — hujjat chiqadi", () async {
    final order = Order.fromJson({...head(71), 'quotes': [quote(2, [priced])]});
    final bytes = await buildKpPdf(
      s: s,
      lang: 'uz',
      order: order,
      quotes: order.latestQuotes,
      storeOf: storeOf,
    );
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(5000));
    File('build/kp_sample.pdf').writeAsBytesSync(bytes);
  });

  test("narxsiz qator bo'lsa — o'sha bo'lim hujjatga tushmaydi", () async {
    final order = Order.fromJson({
      ...head(72),
      'quotes': [quote(2, [priced, unpriced])],
    });
    expect(order.latestQuotes.first.unpricedCount, 1);
    expect(order.latestQuotes.first.allPriced, isFalse);
    final bytes = await buildKpPdf(
      s: s,
      lang: 'uz',
      order: order,
      quotes: order.latestQuotes,
      storeOf: storeOf,
    );
    expect(bytes, isNull, reason: "tayyor bo'lim yo'q — bo'sh hujjat chiqmasin");
  });

  test("ikki do'kon: tayyori chiqadi, kutayotgani kutadi", () async {
    final order = Order.fromJson({
      ...head(73),
      'quotes': [
        quote(1, [priced]),
        quote(2, [unpriced]),
      ],
    });
    final ready = order.latestQuotes.where((q) => q.allPriced).toList();
    expect(ready.length, 1);
    expect(ready.first.storeId, 1);
    final bytes = await buildKpPdf(
      s: s,
      lang: 'uz',
      order: order,
      quotes: order.latestQuotes,
      storeOf: storeOf,
    );
    expect(bytes, isNotNull);
    File('build/kp_sample_multi.pdf').writeAsBytesSync(bytes!);
  });

  test('ruscha blank — Climavent do\'koni', () async {
    final order = Order.fromJson({
      ...head(74),
      'quotes': [
        quote(1, [
          {
            'order_item_id': 1,
            'name': 'Kanal ventilyatorli rekuperator (PKB)',
            'model': 'PKB-500',
            'quantity': 1,
            'price': 13662887,
          },
        ]),
      ],
    });
    final bytes = await buildKpPdf(
      s: lookupS(const Locale('ru')),
      lang: 'ru',
      order: order,
      quotes: order.latestQuotes,
      storeOf: storeOf,
    );
    expect(bytes, isNotNull);
    File('build/kp_sample_blank.pdf').writeAsBytesSync(bytes!);
  });
}
