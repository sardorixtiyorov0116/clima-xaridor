import 'dart:io';

import 'package:climavent/features/catalog/data/models.dart';
import 'package:climavent/features/orders/data/order_models.dart';
import 'package:climavent/features/orders/ui/kp_pdf.dart';
import 'package:climavent/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Namuna: bitta buyurtma, uch do'kon. Ikkitasi narx bergan, uchinchisi kutmoqda —
/// hujjatda faqat tayyor ikkitasi bo'ladi. → build/kp_uch_dokon.pdf
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("uch do'kon — tayyorlari hujjatda", () async {
    const stores = {
      1: Store(
        id: 1,
        name: 'Climavent',
        legalName: '"CLIMAVENT" MChJ',
        tin: '309876543',
        address: 'Toshkent, Shota Rustaveli 115',
        phone: '+998 90 354 78 88',
        email: 'climaventuz@outlook.com',
        website: 'https://climavent.uz',
      ),
      2: Store(
        id: 2,
        name: 'Jihozvent',
        legalName: '"JIHOZVENT" MChJ',
        tin: '305551122',
        address: "Toshkent, Sirg'ali, Nilufar 3-tor ko'chasi, 77",
        phone: '+998 78 777 78 88',
        email: 'jihoz-vent@mail.ru',
        website: 'https://jihozvent.uz',
      ),
      7: Store(
        id: 7,
        name: 'Armavent',
        legalName: '"ARMAVENT" MChJ',
        tin: '307334455',
        address: 'Toshkent, Yunusobod, Amir Temur 108',
        phone: '+998 71 200 55 44',
        email: 'info@armavent.uz',
      ),
    };

    final order = Order.fromJson({
      'id': 124,
      'kind': 'quote',
      'status': 'quote_sent',
      'company_name': '"AIRCOOL" MChJ',
      'company_tin': '301234567',
      'recipient_name': 'Aziz Karimov',
      'recipient_phone': '+998901234567',
      'createdAt': '2026-09-24T09:00:00Z',
      'quotes': [
        {
          'version': 1,
          'store_id': 1,
          'valid_until': '2026-10-08',
          'sent_at': '2026-09-24T09:00:00Z',
          'items': [
            {'order_item_id': 1, 'name': 'Kanal ventilyatorli rekuperator (PKB)', 'model': 'PKB-500', 'quantity': 1, 'price': 13662887},
            {'order_item_id': 2, 'name': 'Havo klapani RSK', 'model': 'RSK 400', 'quantity': 6, 'price': 1245000},
          ],
        },
        {
          'version': 1,
          'store_id': 2,
          'valid_until': '2026-10-08',
          'sent_at': '2026-09-24T09:00:00Z',
          'items': [
            {'order_item_id': 3, 'name': 'Kanalli ventilyator VKPP', 'model': 'ВКПП 90х50-2D35', 'quantity': 2, 'price': 6855123},
            {'order_item_id': 4, 'name': 'Sovitish mashinasi JV (chiller)', 'model': 'JV-65', 'quantity': 1, 'price': 146704360},
          ],
        },
        {
          'version': 1,
          'store_id': 7,
          'valid_until': '2026-10-08',
          'sent_at': '2026-09-24T09:00:00Z',
          'items': [
            {'order_item_id': 5, 'name': 'Issiqlik almashtirgich ТСК', 'model': 'ТСК-80', 'quantity': 4, 'price': null},
          ],
        },
      ],
    });

    final quotes = order.latestQuotes;
    expect(quotes.length, 3);
    expect(quotes.where((q) => q.allPriced).length, 2, reason: 'Armavent hali narx yozmagan');

    final bytes = await buildKpPdf(
      s: lookupS(const Locale('uz')),
      lang: 'uz',
      order: order,
      quotes: quotes,
      storeOf: (id) => stores[id],
    );
    expect(bytes, isNotNull);
    File('build/kp_uch_dokon.pdf').writeAsBytesSync(bytes!);

  });
}
