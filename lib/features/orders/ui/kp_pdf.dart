import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/config.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/data/models.dart';
import '../data/order_models.dart';

/// `3324000` → `3 324 000,00` (namunadagi KP formati).
String _money(num v) {
  final fixed = v.toStringAsFixed(2);
  final parts = fixed.split('.');
  final s = parts[0];
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '$b,${parts[1]}';
}

String _d(DateTime? d) => d == null
    ? '—'
    : '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

const _navy = PdfColor.fromInt(0xFF002854);
const _muted = PdfColor.fromInt(0xFF5B6B82);
const _line = PdfColor.fromInt(0xFFB9C3D1);
const _head = PdfColor.fromInt(0xFFE3F0FB);
const _vat = AppConfig.kpVatRate; // 0.12

/// Do'kon rekvizitlari KP uchun: backend ma'lumoti, bo'sh joylari sozlamadan.
class KpSeller {
  KpSeller(Store? s, int storeId, String lang)
    : name = s?.name ?? '',
      legal =
          s?.legalName ??
          AppConfig.storeLegalName(storeId, lang) ??
          s?.name ??
          '',
      tin = s?.tin,
      phone = s?.phone,
      email = s?.email,
      website = s?.website
          ?.replaceFirst(RegExp(r'^https?://'), '')
          .replaceAll(RegExp(r'/$'), ''),
      address = s?.address,
      logoUrl = s?.logoUrl,
      director = AppConfig.storeDirector(storeId, lang),
      isClimavent = storeId == AppConfig.climaventStoreId;

  final String name;
  final String legal;
  final String? tin;
  final String? phone;
  final String? email;
  final String? website;
  final String? address;
  final String? logoUrl;
  final String? director;
  final bool isClimavent;
}

/// Universal KP (A4) — hamma do'kon uchun bir xil ko'rinish (namuna: «CLimavent предложение КП_13357.pdf»):
/// sotuvchi logosi va rekvizitlari, «№ … от …», «Руководителю …», 8 ustunli jadval (QQS 12% bilan),
/// «Итого», shartlar, amal qilish muddati, imzo.
///
/// Saytdagi narxlar QQS bilan (egasi tasdiqlagan, 21.09.2026): "Сумма с учетом НДС" = mijoz ko'rgan narx,
/// QQSsiz narx va QQS undan ajratib hisoblanadi.
Future<Uint8List> buildKpPdf({
  required S s,
  required String lang,
  required Order order,
  required List<Quote> quotes,
  required Store? Function(int storeId) storeOf,
  bool useImageCache = true,
}) async {
  // Noto Sans ilova ichida — internetsiz ham kirill, lotin va oʻzbek belgilari (ʻ) chiqadi.
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
  );
  Future<pw.MemoryImage> asset(String p) async =>
      pw.MemoryImage((await rootBundle.load(p)).buffer.asUint8List());
  final icons = (
    phone: await asset('assets/brand/kp-ic-phone.png'),
    mail: await asset('assets/brand/kp-ic-mail.png'),
    pin: await asset('assets/brand/kp-ic-pin.png'),
  );
  final climaventMark = await asset('assets/brand/belgi-512.png');
  final climaventWord = await asset('assets/brand/soz-qora.png');

  final doc = pw.Document(
    title: 'KP-${order.id}',
    author: 'Climavent',
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );

  for (final q in quotes) {
    final seller = KpSeller(storeOf(q.storeId), q.storeId, lang);
    final logo = seller.isClimavent
        ? climaventMark
        : await _networkImage(seller.logoUrl, useCache: useImageCache);

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.fromLTRB(40, 32, 36, 36),
        ),
        footer: (ctx) => ctx.pagesCount < 2
            ? pw.SizedBox()
            : pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  '${ctx.pageNumber} / ${ctx.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: _muted),
                ),
              ),
        build: (ctx) => [
          _letterhead(
            seller,
            logo,
            seller.isClimavent ? climaventWord : null,
            icons,
          ),
          pw.SizedBox(height: 18),
          _addressLine(s, order, q),
          pw.SizedBox(height: 16),
          pw.Center(
            child: pw.Text(
              s.kpTitle.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: _navy,
                letterSpacing: 0.5,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              s.kpIntro(seller.legal),
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9.5),
            ),
          ),
          pw.SizedBox(height: 12),
          _table(s, q),
          pw.SizedBox(height: 14),
          _terms(s, order, q),
          pw.SizedBox(height: 22),
          _signature(s, seller),
        ],
      ),
    );
  }
  return doc.save();
}

/// Do'kon logosi: avval ilova keshidan (katalogda ko'rilgan bo'lsa internet kerak emas), bo'lmasa internetdan.
Future<pw.MemoryImage?> _networkImage(
  String? url, {
  bool useCache = true,
}) async {
  if (url == null) return null;
  if (useCache) {
    try {
      final file = await DefaultCacheManager()
          .getSingleFile(url)
          .timeout(const Duration(seconds: 6));
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) return pw.MemoryImage(bytes);
    } catch (_) {
      // Kesh ishlamasa — to'g'ridan-to'g'ri yuklaymiz.
    }
  }
  try {
    final r = await Dio().get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    final b = r.data;
    return b == null || b.isEmpty
        ? null
        : pw.MemoryImage(Uint8List.fromList(b));
  } catch (_) {
    return null;
  }
}

/// Tepadagi rekvizitlar chizig'i: chapda logo va nom, o'ngda telefon · e-pochta/sayt · manzil.
pw.Widget _letterhead(
  KpSeller s,
  pw.MemoryImage? logo,
  pw.MemoryImage? wordmark,
  ({pw.MemoryImage phone, pw.MemoryImage mail, pw.MemoryImage pin}) icons,
) {
  pw.Widget row(pw.MemoryImage icon, String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 5),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Image(icon, width: 15, height: 15),
        pw.SizedBox(width: 7),
        pw.Expanded(
          child: pw.Text(
            text,
            style: const pw.TextStyle(fontSize: 8.5, color: _navy),
          ),
        ),
      ],
    ),
  );
  final contacts = <pw.Widget>[
    if (s.phone != null) row(icons.phone, s.phone!),
    if (s.email != null || s.website != null)
      row(icons.mail, [s.email, s.website].whereType<String>().join(', ')),
    if (s.address != null)
      row(icons.pin, [if (s.legal.isNotEmpty) s.legal, s.address].join(', ')),
  ];
  return pw.Column(
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            flex: 5,
            child: pw.Row(
              children: [
                if (logo != null) pw.Image(logo, width: 44, height: 44),
                if (logo != null) pw.SizedBox(width: 8),
                if (wordmark != null)
                  pw.Image(wordmark, height: 26)
                else
                  pw.Flexible(
                    child: pw.Text(
                      s.name,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: _navy,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            flex: 5,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: contacts,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Container(height: 1.2, color: _navy),
    ],
  );
}

/// «№ 77/1 · от 21.09.2026 г.» chapda, «Руководителю · KOMPANIYA» o'ngda.
pw.Widget _addressLine(S s, Order order, Quote q) {
  final to = order.companyName ?? order.recipientName;
  final bold = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('№ ${order.id}/${q.version}', style: bold),
          pw.Text(s.kpDated(_d(q.sentAt ?? order.createdAt)), style: bold),
        ],
      ),
      if (to != null)
        pw.Container(
          width: 220,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                order.companyName != null ? s.kpToHead : s.kpTo,
                style: bold,
              ),
              pw.Text(to, style: bold),
              if (order.companyTin != null)
                pw.Text(
                  '${s.companyTin}: ${order.companyTin}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
            ],
          ),
        ),
    ],
  );
}

pw.Widget _table(S s, Quote q) {
  pw.Widget cell(
    String t, {
    bool b = false,
    pw.TextAlign align = pw.TextAlign.center,
    PdfColor? color,
    double size = 8.3,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
    child: pw.Text(
      t,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: size,
        fontWeight: b ? pw.FontWeight.bold : null,
        color: color,
      ),
    ),
  );
  double net(double gross) => gross / (1 + _vat);
  var sumNet = 0.0, sumVat = 0.0, sumGross = 0.0;
  final rows = <pw.TableRow>[];
  for (var i = 0; i < q.items.length; i++) {
    final it = q.items[i];
    final gross = it.sum;
    if (gross != null) {
      sumGross += gross;
      sumNet += net(gross);
      sumVat += gross - net(gross);
    }
    rows.add(
      pw.TableRow(
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          cell('${i + 1}'),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(it.name, style: const pw.TextStyle(fontSize: 8.3)),
                if (it.model.isNotEmpty)
                  pw.Text(
                    it.model,
                    style: const pw.TextStyle(fontSize: 7.5, color: _muted),
                  ),
              ],
            ),
          ),
          cell(s.kpUnit),
          cell('${it.qty}'),
          if (it.price == null) ...[
            cell(s.kpUnpricedCell, color: _muted, size: 7.5),
            cell('—', color: _muted),
            cell('—', color: _muted),
            cell('—', color: _muted),
          ] else ...[
            cell(_money(net(it.price!)), align: pw.TextAlign.right, size: 7.6),
            cell(_money(net(gross!)), align: pw.TextAlign.right, size: 7.6),
            cell(
              _money(gross - net(gross)),
              align: pw.TextAlign.right,
              size: 7.6,
            ),
            cell(_money(gross), align: pw.TextAlign.right, size: 7.6),
          ],
        ],
      ),
    );
  }
  return pw.Table(
    border: pw.TableBorder.all(color: _line, width: 0.6),
    columnWidths: const {
      0: pw.FixedColumnWidth(18),
      1: pw.FlexColumnWidth(3.3),
      2: pw.FixedColumnWidth(30),
      3: pw.FixedColumnWidth(34),
      4: pw.FixedColumnWidth(66),
      5: pw.FixedColumnWidth(70),
      6: pw.FixedColumnWidth(62),
      7: pw.FixedColumnWidth(72),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _head),
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        repeat: true,
        children: [
          cell('№', b: true),
          cell(s.kpColName, b: true),
          cell(s.kpColUnit, b: true, size: 7.5),
          cell(s.kpColQty, b: true, size: 7.5),
          cell(s.kpColUnitPrice, b: true),
          cell(s.kpColAmount, b: true),
          cell(s.kpColVat, b: true),
          cell(s.kpColTotalVat, b: true),
        ],
      ),
      ...rows,
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _head),
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          cell(''),
          cell(s.kpTotalRow, b: true, align: pw.TextAlign.right),
          cell(''),
          cell(''),
          cell(''),
          cell(_money(sumNet), b: true, align: pw.TextAlign.right, size: 7.6),
          cell(_money(sumVat), b: true, align: pw.TextAlign.right, size: 7.6),
          cell(_money(sumGross), b: true, align: pw.TextAlign.right, size: 7.6),
        ],
      ),
    ],
  );
}

/// Shartlar (sotuvchi yozgan bo'lsa) va narxlarning amal qilish muddati — markazda.
pw.Widget _terms(S s, Order order, Quote q) {
  const st = pw.TextStyle(fontSize: 9);
  final lines = <String>[
    ?q.deliveryTerms,
    ?q.paymentTerms,
    ?q.note,
    if (q.unpricedCount > 0) s.cartUnpriced(q.unpricedCount),
    s.kpVatNote,
  ];
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      for (final l in lines)
        pw.Text(l, textAlign: pw.TextAlign.center, style: st),
      pw.SizedBox(height: 2),
      pw.Text(
        s.kpValidRange(_d(q.sentAt ?? order.createdAt), _d(q.validUntil)),
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    ],
  );
}

/// «С уважением, Директор ООО «…» ____ F.I.O.» — direktor ma'lum bo'lmasa, imzo uchun joy.
pw.Widget _signature(S s, KpSeller seller) {
  final bold = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(s.kpRegards, style: bold),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            seller.director != null
                ? s.kpDirectorOf(seller.legal)
                : s.kpHeadOf(seller.legal),
            style: bold,
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(14, 0, 14, 3),
              child: pw.Container(height: 0.6, color: _line),
            ),
          ),
          pw.Text(seller.director ?? '', style: bold),
          if (seller.director == null) pw.SizedBox(width: 110),
        ],
      ),
    ],
  );
}

/// PDF ni ulashish oynasi orqali saqlash yoki yuborish (Telegram, Fayllar, e-pochta).
Future<void> shareKpPdf(Uint8List bytes, String fileName) =>
    Printing.sharePdf(bytes: bytes, filename: fileName);
