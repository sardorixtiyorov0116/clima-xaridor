import 'dart:io';

import 'package:climavent/features/catalog/data/models.dart';
import 'package:climavent/features/orders/data/order_models.dart';
import 'package:climavent/features/orders/ui/kp_pdf.dart';
import 'package:climavent/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chegaraviy holat: 10 ta tovar 10 ta do'kondan. Hujjat bir necha sahifa bo'ladi —
/// ustun sarlavhalari har sahifada takrorlanishi kerak. → build/kp_on_dokon.pdf
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("o'n do'kon — sarlavha har sahifada takrorlanadi", () async {
    const names = [
      'Climavent', 'Jihozvent', 'Armavent', 'VENTS US', 'Havotex',
      'Klimat Pro', 'Ventmash', 'Aeroline', 'Termoblok', 'Shamol',
    ];
    final stores = {
      for (var i = 0; i < names.length; i++)
        i + 1: Store(
          id: i + 1,
          name: names[i],
          legalName: '"${names[i].toUpperCase()}" MChJ',
          tin: '30${1000000 + i * 111111}',
          address: 'Toshkent, ${i + 1}-uy',
          phone: '+998 71 200 00 0$i',
          email: 'info@${names[i].toLowerCase().replaceAll(' ', '')}.uz',
          website: 'https://climavent.uz',
        ),
    };

    final order = Order.fromJson({
      'id': 130,
      'kind': 'quote',
      'status': 'quote_sent',
      'company_name': '"AIRCOOL" MChJ',
      'company_tin': '301234567',
      'recipient_name': 'Aziz Karimov',
      'recipient_phone': '+998901234567',
      'createdAt': '2026-09-24T09:00:00Z',
      'quotes': [
        for (var i = 0; i < names.length; i++)
          {
            'version': 1,
            'store_id': i + 1,
            'valid_until': '2026-10-08',
            'sent_at': '2026-09-24T09:00:00Z',
            'items': [
              {
                'order_item_id': i + 1,
                'name': 'Uskuna ${i + 1}',
                'model': 'MODEL-${100 + i}',
                'quantity': i + 1,
                'price': 1250000 + i * 340000,
              },
            ],
          },
      ],
    });

    final quotes = order.latestQuotes;
    expect(quotes.length, 10);
    final bytes = await buildKpPdf(
      s: lookupS(const Locale('uz')),
      lang: 'uz',
      order: order,
      quotes: quotes,
      storeOf: (id) => stores[id],
    );
    expect(bytes, isNotNull);
    File('build/kp_on_dokon.pdf').writeAsBytesSync(bytes!);
  });
}
