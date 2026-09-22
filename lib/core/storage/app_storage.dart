import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/session.dart';

/// Tokenlar — faqat himoyalangan xotirada (Android Keystore / iOS Keychain).
/// Oddiy sozlamalar (til, mavzu) — SharedPreferences.
class AppStorage {
  AppStorage(this._prefs);

  final SharedPreferences _prefs;
  static const _secure = FlutterSecureStorage();

  static const _kUserId = 'user_id';
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kPhone = 'phone';
  static const _kLocale = 'locale';
  static const _kTheme = 'theme';
  static const _kOnboarded = 'onboarded';
  static const _kProfile = 'profile_cache';

  static Future<AppStorage> open() async =>
      AppStorage(await SharedPreferences.getInstance());

  // ── sessiya ──
  Future<Session?> readSession() async {
    try {
      final all = await _secure.readAll();
      final id = all[_kUserId];
      final access = all[_kAccess];
      if (id == null || id.isEmpty || access == null || access.isEmpty) return null;
      return Session(
        userId: id,
        accessToken: access,
        refreshToken: all[_kRefresh],
        phone: all[_kPhone] ?? '',
      );
    } catch (_) {
      // Keystore buzilgan bo'lsa (qurilma tiklangan) — qaytadan kirish.
      await clearSession();
      return null;
    }
  }

  Future<void> writeSession(Session s) async {
    await _secure.write(key: _kUserId, value: s.userId);
    await _secure.write(key: _kAccess, value: s.accessToken);
    await _secure.write(key: _kPhone, value: s.phone);
    if (s.refreshToken != null) {
      await _secure.write(key: _kRefresh, value: s.refreshToken);
    }
  }

  Future<void> clearSession() async {
    for (final k in [_kUserId, _kAccess, _kRefresh, _kPhone]) {
      await _secure.delete(key: k);
    }
    await _prefs.remove(_kProfile);
  }

  /// Oxirgi ma'lum profil (ism) — ilova ochilganda darhol ko'rsatish uchun.
  UserProfile? get cachedProfile {
    final raw = _prefs.getString(_kProfile);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheProfile(UserProfile? p) =>
      p == null ? _prefs.remove(_kProfile) : _prefs.setString(_kProfile, jsonEncode(p.toJson()));

  // ── sozlamalar ──
  Locale? get locale {
    final code = _prefs.getString(_kLocale);
    return code == null ? null : Locale(code);
  }

  Future<void> setLocale(Locale l) => _prefs.setString(_kLocale, l.languageCode);

  ThemeMode get themeMode =>
      ThemeMode.values.asNameMap()[_prefs.getString(_kTheme)] ?? ThemeMode.system;

  Future<void> setThemeMode(ThemeMode m) => _prefs.setString(_kTheme, m.name);

  /// Sevimlilar, savat, qidiruv tarixi — kichik ro'yxatlar.
  List<String> list(String key) => _prefs.getStringList(key) ?? const [];
  Future<void> setList(String key, List<String> v) => _prefs.setStringList(key, v);

  bool get onboarded => _prefs.getBool(_kOnboarded) ?? false;

  Future<void> setOnboarded() => _prefs.setBool(_kOnboarded, true);
}
