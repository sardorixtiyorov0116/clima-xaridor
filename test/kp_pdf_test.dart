import 'dart:io';

import 'package:climavent/features/catalog/data/models.dart';
import 'package:climavent/features/orders/data/order_models.dart';
import 'package:climavent/features/orders/ui/kp_pdf.dart';
import 'package:climavent/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Namunaviy KP → build/kp_sample.pdf (ko'rib chiqish uchun). Internet kerak (shrift).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('KP PDF yaratiladi', () async {
    HttpOverrides.global = null; // namunada haqiqiy do'kon logosi internetdan yuklansin
    final order = Order.fromCreate({
      'newOrder': {
        'id': 71,
        'kind': 'quote',
        'status': 'new',
        'source': 'site_kp',
        'company_name': '"AIRCOOL" MChJ',
        'company_tin': '301234567',
        'recipient_name': 'Aziz Karimov',
        'recipient_phone': '+998901234567',
        'location': "Toshkent, Lolazor, Fidokor ko'chasi, 38",
        'createdAt': '2026-09-21T10:00:00Z',
      },
      'quotes': [
        {
          'version': 1,
          'store_id': 2,
          'valid_until': '2026-10-01',
          'sent_at': '2026-09-21T10:00:00Z',
          'items': [
            {'order_item_id': 1, 'name': 'Kanalli ventilyator VKPP', 'model': 'ВКПП 90х50-2D35', 'quantity': 2, 'price': 6855123},
            {'order_item_id': 2, 'name': "Sovitish mashinasi JV (chiller)", 'model': 'JV-65', 'quantity': 1, 'price': 146704360},
            {'order_item_id': 3, 'name': 'Issiqlik almashtirgich ТСК', 'model': 'ТСК', 'quantity': 4, 'price': null},
          ],
        },
      ],
    });
    final s = lookupS(const Locale('uz'));
    const store = Store(
      id: 2,
      name: 'Jihozvent',
      address: "Toshkent, Sirg'ali, Daryobo'yi MFY, Nilufar 3-tor ko'chasi, 77",
      phone: '+998 (78) 777 78 88',
      email: 'jihoz-vent@mail.ru',
      website: 'https://jihozvent.uz',
      logoUrl: 'https://res.cloudinary.com/dne7ddv2a/image/upload/v1788514144/climavent/products/v0hke6naycsfimxlkbdc.png',
    );
    final bytes = await buildKpPdf(s: s, lang: 'uz', order: order, quotes: order.latestQuotes, storeOf: (_) => store, useImageCache: false);
    expect(bytes.length, greaterThan(5000));
    File('build/kp_sample.pdf').writeAsBytesSync(bytes);
    // Climavent do'koni — rasmiy blankda.
    final blankOrder = Order.fromJson({
      'id': 72, 'kind': 'quote', 'status': 'quote_sent', 'company_name': '"AIRCOOL" MChJ', 'company_tin': '301234567',
      'recipient_name': 'Aziz Karimov', 'recipient_phone': '+998901234567', 'createdAt': '2026-09-21T10:00:00Z',
      'quotes': [
        {'version': 1, 'store_id': 1, 'valid_until': '2026-10-01', 'items': [
          {'order_item_id': 1, 'name': 'Kanal ventilyatorli rekuperator (PKB)', 'model': 'PKB-500', 'quantity': 1, 'price': 13662887},
        ]},
      ],
    });
    final ru = lookupS(const Locale('ru'));
    const climavent = Store(
      id: 1,
      name: 'Climavent',
      address: 'Toshkent, Shota Rustaveli 115',
      phone: '+998 90 354 78 88',
      email: 'climaventuz@outlook.com',
      website: 'https://climavent.uz',
    );
    final blank =
        await buildKpPdf(s: ru, lang: 'ru', order: blankOrder, quotes: blankOrder.latestQuotes, storeOf: (_) => climavent);
    File('build/kp_sample_blank.pdf').writeAsBytesSync(blank);
    expect(order.latestQuotes.first.unpricedCount, 1);
    expect(order.latestQuotes.first.total, 6855123 * 2 + 146704360);
  });
}
