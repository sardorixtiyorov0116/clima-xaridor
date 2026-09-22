import '../../../core/api/api_client.dart';
import 'session.dart';

/// `POST /users/login` natijasi.
sealed class LoginResult {}

/// Raqam yangi — rozilik kerak. SMS hali yuborilmagan.
class ConsentRequired extends LoginResult {
  ConsentRequired({required this.termsVersion, required this.privacyVersion});
  final String termsVersion;
  final String privacyVersion;
}

/// SMS yuborildi.
class CodeSent extends LoginResult {
  CodeSent({required this.verificationKey, required this.userId});
  final String verificationKey;
  final String userId;
}

class Consent {
  const Consent(this.termsVersion, this.privacyVersion);
  final String termsVersion;
  final String privacyVersion;

  Map<String, String> toJson() =>
      {'terms_version': termsVersion, 'privacy_version': privacyVersion};
}

/// Kirish backend bilan aynan sayt kabi ishlaydi (climavent.uz, LoginMob):
/// 1) login + check_consent → consent_required yoki otpinfo
/// 2) verify-otp → client + tokens
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<LoginResult> requestCode(String phone, {Consent? consent}) async {
    final r = await _api.post('/users/login', {
      'phone_number': phone,
      'check_consent': true,
      ...?consent?.toJson(),
    });
    if (r['consent_required'] == true) {
      return ConsentRequired(
        termsVersion: '${(r['terms'] as Map?)?['version'] ?? ''}',
        privacyVersion: '${(r['privacy'] as Map?)?['version'] ?? ''}',
      );
    }
    final key = (r['otpinfo'] as Map?)?['details']?.toString();
    final userId = (r['user'] as Map?)?['id']?.toString();
    if (key == null || userId == null) {
      throw ApiException(ApiErrorKind.unknown);
    }
    return CodeSent(verificationKey: key, userId: userId);
  }

  Future<({Session session, UserProfile profile})> verify({
    required String phone,
    required CodeSent sent,
    required String code,
    Consent? consent,
  }) async {
    final r = await _api.post('/users/verify-otp', {
      'phone_number': phone,
      'verification_key': sent.verificationKey,
      'otp': code,
      'userId': sent.userId,
      // Backend mobil mijozga uzun refresh token beradi (№29, 3-band).
      'client': 'mobile',
      ...?consent?.toJson(),
    });
    final tokens = (r['tokens'] as Map?) ?? const {};
    final access = tokens['accessToken']?.toString();
    if (access == null || access.isEmpty) throw ApiException(ApiErrorKind.unknown);
    final profile = UserProfile.fromJson(r, fallbackId: sent.userId, fallbackPhone: phone);
    final session = Session(
      userId: profile.id.isEmpty ? sent.userId : profile.id,
      accessToken: access,
      refreshToken: tokens['refreshToken']?.toString(),
      phone: phone,
    );
    return (session: session, profile: profile);
  }

  /// `POST /users/refresh` — yangi juftlik (rotatsiya). Refresh yaroqsiz bo'lsa null.
  /// Tarmoq xatosida istisno otiladi — bunda foydalanuvchini chiqarmaymiz.
  Future<Session?> refresh(Session s) async {
    final rt = s.refreshToken;
    if (rt == null || rt.isEmpty) return null;
    try {
      final r = await _api.postNoAuth('/users/refresh', {'refresh_token': rt});
      final t = (r['tokens'] as Map?) ?? r;
      final access = (t['accessToken'] ?? t['access_token'])?.toString();
      if (access == null || access.isEmpty) return null;
      return Session(
        userId: s.userId,
        accessToken: access,
        refreshToken: (t['refreshToken'] ?? t['refresh_token'])?.toString() ?? rt,
        phone: s.phone,
      );
    } on ApiException catch (e) {
      // 401/403 — refresh bekor; 404 — endpoint hali yo'q (backend №29). Ikkalasida ham qayta kirish.
      if (e.kind == ApiErrorKind.unauthorized || (e.status != null && e.status! >= 400 && e.status! < 500)) {
        return null;
      }
      rethrow;
    }
  }

  Future<UserProfile> fetchProfile(Session s) async {
    final r = await _api.get('/users/one/${s.userId}');
    return UserProfile.fromJson(r, fallbackId: s.userId, fallbackPhone: s.phone);
  }

  Future<void> updateName(Session s, {required String name, String? surname}) async {
    await _api.patch('/users/update/${s.userId}', {
      'name': name,
      if (surname != null && surname.isNotEmpty) 'surname': surname,
    });
  }

  Future<void> signOut(Session s) async {
    try {
      await _api.post('/users/signout', {'refresh_token': s.refreshToken});
    } catch (_) {
      // Chiqish lokal ravishda baribir bajariladi.
    }
  }
}
