/// Ilova sozlamalari. `--dart-define=API_BASE=...` bilan almashtirsa bo'ladi.
abstract final class AppConfig {
  static const apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://climavent-back-production.up.railway.app/api',
  );
  static const siteBase = 'https://climavent.uz';
  static const termsUrl = '$siteBase/foydalanish-shartlari';
  static const privacyUrl = '$siteBase/maxfiylik';
  static const supportPhone = '+998903547888';
  static const supportPhoneLabel = '+998 90 354 78 88';
  /// KP (tijorat taklifi) sozlamalari.
  static const climaventStoreId = 1;
  static const kpVatRate = 0.12; // QQS 12%. Saytdagi narxlar QQS bilan (egasi tasdiqlagan, 21.09.2026)

  /// Backendda `legal_name` bo'sh bo'lsa — ma'lum do'konlar uchun yuridik nom.
  static String? storeLegalName(int storeId, String lang) => switch (storeId) {
        1 => switch (lang) { 'ru' => 'ООО «CLIMAVENT»', 'en' => 'CLIMAVENT LLC', _ => '"CLIMAVENT" MChJ' },
        _ => null,
      };

  /// KP ga imzo qo'yadigan rahbar (backendda bunday maydon yo'q).
  static String? storeDirector(int storeId, String lang) => switch (storeId) {
        1 => switch (lang) { 'ru' => 'Расулов Ж.С.', 'en' => 'J.S. Rasulov', _ => 'Rasulov J.S.' },
        _ => null,
      };

  static const appVersion = '0.4.1';

  /// Backend kodni qayta yuborishga ruxsat beradigan oraliq (saytdagidek).
  static const otpResendSeconds = 120;
  static const otpLength = 5;
}
