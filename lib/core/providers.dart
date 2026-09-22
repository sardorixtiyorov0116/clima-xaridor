import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/session.dart';
import 'api/api_client.dart';
import 'storage/app_storage.dart';

/// `main()` da ochiladi va override qilinadi.
final storageProvider = Provider<AppStorage>((_) => throw UnimplementedError());
final initialSessionProvider = Provider<Session?>((_) => null);

// ── sessiya ──
class SessionController extends Notifier<Session?> {
  @override
  Session? build() => ref.read(initialSessionProvider);

  Future<void> signIn(Session s, UserProfile profile) async {
    await ref.read(storageProvider).writeSession(s);
    ref.read(profileProvider.notifier).set(profile);
    state = s;
  }

  Future<String?>? _refreshing;

  /// Bir vaqtda kelgan bir nechta 401 — bitta yangilash so'rovi.
  Future<String?> refreshAccess() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<String?> _doRefresh() async {
    final s = state;
    if (s == null) return null;
    // Tarmoq xatosi istisno bo'lib yuqoriga chiqadi — ApiClient foydalanuvchini chiqarmaydi.
    final next = await ref.read(authRepositoryProvider).refresh(s);
    if (next == null) return null;
    await ref.read(storageProvider).writeSession(next);
    state = next;
    return next.accessToken;
  }

  Future<void> signOut({bool callBackend = true}) async {
    final s = state;
    if (s == null) return;
    state = null;
    ref.read(profileProvider.notifier).set(null);
    await ref.read(storageProvider).clearSession();
    if (callBackend) await ref.read(authRepositoryProvider).signOut(s);
  }
}

final sessionProvider = NotifierProvider<SessionController, Session?>(SessionController.new);

class ProfileController extends Notifier<UserProfile?> {
  @override
  UserProfile? build() {
    final s = ref.watch(sessionProvider);
    if (s == null) return null;
    // Keshdagi ism darhol, yangisi fonda keladi.
    Future.microtask(refresh);
    return stateOrNull ?? ref.read(storageProvider).cachedProfile;
  }

  void set(UserProfile? p) {
    state = p;
    ref.read(storageProvider).cacheProfile(p);
  }

  Future<void> refresh() async {
    final s = ref.read(sessionProvider);
    if (s == null) return;
    try {
      set(await ref.read(authRepositoryProvider).fetchProfile(s));
    } catch (_) {
      // Tarmoq yo'q — mavjud holat qoladi.
    }
  }
}

final profileProvider = NotifierProvider<ProfileController, UserProfile?>(ProfileController.new);

// ── tarmoq ──
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    readToken: () => ref.read(sessionProvider)?.accessToken,
    refresh: () => ref.read(sessionProvider.notifier).refreshAccess(),
    onUnauthorized: () => ref.read(sessionProvider.notifier).signOut(callBackend: false),
  );
});

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ref.read(apiClientProvider)));

// ── sozlamalar ──
const supportedLocales = [Locale('uz'), Locale('ru'), Locale('en')];

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => ref.read(storageProvider).locale;

  Future<void> set(Locale l) async {
    state = l;
    await ref.read(storageProvider).setLocale(l);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(LocaleController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(storageProvider).themeMode;

  Future<void> set(ThemeMode m) async {
    state = m;
    await ref.read(storageProvider).setThemeMode(m);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
