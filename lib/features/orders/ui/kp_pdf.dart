import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/config.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/data/models.dart';
import '../data/order_models.dart';

const _cols = <int, pw.TableColumnWidth>{
  0: pw.FixedColumnWidth(18),
  1: pw.FlexColumnWidth(3.3),
  2: pw.FixedColumnWidth(30),
  3: pw.FixedColumnWidth(34),
  4: pw.FixedColumnWidth(66),
  5: pw.FixedColumnWidth(70),
  6: pw.FixedColumnWidth(62),
  7: pw.FixedColumnWidth(72),
};

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
      director = AppConfig.storeDirector(storeId, lang);

  final String name;
  final String legal;
  final String? tin;
  final String? phone;
  final String? email;
  final String? website;
  final String? address;
  final String? director;
}

/// Tepadagi rekvizitlar chizig'i: chapda Climavent logosi va nomi, o'ngda
/// telefon · e-pochta/sayt · manzil. Blank hamma do'kon uchun bir xil.
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
pw.Widget _addressLine(S s, Order order, int version, DateTime? dated) {
  final to = order.companyName ?? order.recipientName;
  final bold = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('№ ${order.id}/$version', style: bold),
          pw.Text(s.kpDated(_d(dated)), style: bold),
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

/// Izohlar va narxlarning amal qilish muddati — markazda.
pw.Widget _terms(S s, List<String> extra, String from, String to) {
  const st = pw.TextStyle(fontSize: 9);
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      for (final l in extra)
        pw.Text(l, textAlign: pw.TextAlign.center, style: st),
      pw.Text(s.kpVatNote, textAlign: pw.TextAlign.center, style: st),
      pw.Text(s.kpDisclaimer, textAlign: pw.TextAlign.center, style: st),
      pw.SizedBox(height: 2),
      pw.Text(
        s.kpValidRange(from, to),
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    ],
  );
}

/// «Hurmat bilan, "CLIMAVENT" MChJ direktori ____ F.I.O.»
pw.Widget _signature(S s, KpSeller v) {
  final bold = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(s.kpRegards, style: bold),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            v.director != null ? s.kpDirectorOf(v.legal) : s.kpHeadOf(v.legal),
            style: bold,
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(14, 0, 14, 3),
              child: pw.Container(height: 0.6, color: _line),
            ),
          ),
          pw.Text(v.director ?? '', style: bold),
          if (v.director == null) pw.SizedBox(width: 110),
        ],
      ),
    ],
  );
}

/// Bitta jadval: hamma qator ketma-ket raqamlanadi, oxirida bitta «Jami».
/// Tovar qaysi do'konniki ekani xaridorga ko'rsatilmaydi — u Climavent bilan
/// ishlaydi (egasi, 24.09.2026). Ichki hisob-kitob adminkada qoladi.
pw.Widget _table(S s, List<Quote> ready) {
  pw.Widget cell(
    String t, {
    bool b = false,
    pw.TextAlign align = pw.TextAlign.center,
    double size = 8.3,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
    child: pw.Text(
      t,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: size,
        fontWeight: b ? pw.FontWeight.bold : null,
      ),
    ),
  );
  double net(double gross) => gross / (1 + _vat);

  var no = 0;
  var sumNet = 0.0, sumVat = 0.0, sumGross = 0.0;
  final rows = <pw.TableRow>[];
  for (final q in ready) {
    for (final it in q.items) {
      final gross = it.sum!;
      sumGross += gross;
      sumNet += net(gross);
      sumVat += gross - net(gross);
      no++;
      rows.add(
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            cell('$no'),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 5,
              ),
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
            cell(_money(net(it.price!)), align: pw.TextAlign.right, size: 7.6),
            cell(_money(net(gross)), align: pw.TextAlign.right, size: 7.6),
            cell(
              _money(gross - net(gross)),
              align: pw.TextAlign.right,
              size: 7.6,
            ),
            cell(_money(gross), align: pw.TextAlign.right, size: 7.6),
          ],
        ),
      );
    }
  }
  return pw.Table(
    border: pw.TableBorder.all(color: _line, width: 0.6),
    columnWidths: _cols,
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _head),
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        repeat: true, // uzun hujjatda sarlavha har sahifada takrorlansin
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

/// KP (A4) — CLIMAVENT nomidan bitta hujjat (egasi, 24.09.2026).
///
/// Xaridor bitta taklif, bitta jami, bitta imzo va bitta aloqa nuqtasini ko'radi.
/// Tovar qaysi do'kondan kelishi hujjatda ko'rsatilmaydi: pul Climavent hisobiga
/// tushadi, fakturani Climavent yozadi, yetkazishni Climavent kuryeri qiladi.
/// Ichkarida har qator o'z do'koniga bog'liq bo'lib qoladi — hisob-kitob adminkada.
///
/// Narxsiz qator hujjatga TUSHMAYDI: faqat hamma qatoriga narx yozilgan do'kon
/// bo'limi kiradi. Do'kon narx yozgach KP qayta quriladi, shu sabab bir do'konning
/// kechikishi boshqasini to'smaydi.
///
/// Saytdagi narxlar QQS bilan (egasi, 21.09.2026): mijoz ko'rgan narx «QQS bilan
/// summa», QQSsiz narx va QQS undan ajratib hisoblanadi.
///
/// Tayyor bo'lim bo'lmasa — `null`.
Future<Uint8List?> buildKpPdf({
  required S s,
  required String lang,
  required Order order,
  required List<Quote> quotes,
  required Store? Function(int storeId) storeOf,
}) async {
  final ready = quotes.where((q) => q.allPriced).toList();
  if (ready.isEmpty) return null;

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
  final mark = await asset('assets/brand/belgi-512.png');
  final word = await asset('assets/brand/soz-qora.png');
  final house = KpSeller(
    storeOf(AppConfig.climaventStoreId),
    AppConfig.climaventStoreId,
    lang,
  );

  // Muddat do'konlarda har xil bo'lsa — eng qisqasi olinadi, aks holda hujjat
  // amal qilmay qolgan narxni va'da qilib qo'yadi.
  DateTime? until;
  for (final q in ready) {
    final v = q.validUntil;
    if (v != null && (until == null || v.isBefore(until))) until = v;
  }
  // Shartlar sarlavhasi bilan yozilsin: aks holda hujjatda «3 oy» kabi yolg'iz
  // so'z paydo bo'ladi va nimaga tegishli ekani tushunarsiz qoladi.
  // Bir xil shartlar takrorlanmasin.
  final extra = <String>{
    for (final q in ready) ...[
      if (q.deliveryTerms != null) '${s.kpDeliveryTerms}: ${q.deliveryTerms}',
      if (q.paymentTerms != null) '${s.kpPaymentTerms}: ${q.paymentTerms}',
      ?q.note,
    ],
  }.toList();
  final first = ready.first;
  final version = ready.map((q) => q.version).reduce((a, b) => a > b ? a : b);

  final doc = pw.Document(
    title: 'KP-${order.id}',
    author: 'Climavent',
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );
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
        _letterhead(house, mark, word, icons),
        pw.SizedBox(height: 18),
        _addressLine(s, order, version, first.sentAt ?? order.createdAt),
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
            s.kpIntro(house.legal),
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 9.5),
          ),
        ),
        pw.SizedBox(height: 12),
        _table(s, ready),
        pw.SizedBox(height: 14),
        _terms(s, extra, _d(first.sentAt ?? order.createdAt), _d(until)),
        pw.SizedBox(height: 22),
        _signature(s, house),
      ],
    ),
  );
  return doc.save();
}

/// PDF ni ulashish oynasi orqali saqlash yoki yuborish (Telegram, Fayllar, e-pochta).
Future<void> shareKpPdf(Uint8List bytes, String fileName) =>
    Printing.sharePdf(bytes: bytes, filename: fileName);
