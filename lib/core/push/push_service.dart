import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/auth/data/session.dart';
import '../../features/chat/chat_providers.dart';
import '../../features/orders/orders_providers.dart';
import '../config.dart';
import '../providers.dart';

/// Ilova yopiq paytda kelgan xabar — bildirishnomani tizimning o'zi ko'rsatadi,
/// bu yerda faqat Firebase ishga tushadi.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Push-bildirishnomalar (backend №29, 4-band):
/// - kirgandan keyin ruxsat so'raladi va qurilma tokeni `POST /devices` ga yoziladi;
/// - ilova ochiq paytda kelgan xabar ham ko'rsatiladi;
/// - bildirishnoma bosilsa — buyurtma yoki KP sahifasi ochiladi;
/// - chiqishda token backenddan o'chiriladi.
class PushService {
  PushService(this._ref);
  final Ref _ref;

  static const _channel = AndroidNotificationChannel(
    'orders',
    'Buyurtmalar va KP',
    description: 'KP tayyor, buyurtma holati, yetkazish',
    importance: Importance.high,
  );

  /// Do'kon xabarlari (backend №34: `channel_id: "chat"`).
  static const _chatChannel = AndroidNotificationChannel(
    'chat',
    'Doʻkon xabarlari',
    description: 'Doʻkonlar bilan yozishmalar',
    importance: Importance.high,
  );

  final _local = FlutterLocalNotificationsPlugin();
  GoRouter? _router;
  String? _token;
  bool _ready = false;

  Future<void> init(GoRouter router) async {
    _router = router;
    if (kIsWeb || _ready) return;
    _ready = true;
    try {
      await _local.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('ic_notification')),
        onDidReceiveNotificationResponse: (r) => _openPayload(r.payload),
      );
      final android = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(_channel);
      await android?.createNotificationChannel(_chatChannel);

      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data));
      FirebaseMessaging.instance.onTokenRefresh.listen((t) {
        _token = t;
        _register();
      });
      // Ilova bildirishnoma bosilib ochilgan bo'lsa — kerakli sahifaga.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _open(initial.data));
      }
      if (_ref.read(sessionProvider) != null) await onSignedIn();
    } catch (e) {
      debugPrint('push: init xatosi: $e');
    }
  }

  /// Kirgandan keyin (va ilova ochilganda, agar kirgan bo'lsa): ruxsat + token + backendga yozish.
  Future<void> onSignedIn() async {
    if (kIsWeb) return;
    try {
      final perm = await FirebaseMessaging.instance.requestPermission();
      if (perm.authorizationStatus == AuthorizationStatus.denied) return;
      _token = await FirebaseMessaging.instance.getToken();
      await _register();
    } catch (e) {
      debugPrint('push: token xatosi: $e');
    }
  }

  /// Chiqishdan oldin — shu qurilmaga boshqa xabar kelmasin.
  Future<void> onSigningOut(Session s) async {
    final t = _token;
    if (t == null) return;
    try {
      await _ref.read(apiClientProvider).deleteWithToken('/devices/${Uri.encodeComponent(t)}', s.accessToken);
    } catch (_) {}
  }

  Future<void> _register() async {
    final t = _token;
    if (t == null || _ref.read(sessionProvider) == null) return;
    try {
      await _ref.read(apiClientProvider).post('/devices', {'platform': 'android', 'token': t});
      debugPrint('push: qurilma ro\'yxatdan o\'tdi');
    } catch (e) {
      // Backend xaridor tokenini hali qabul qilmasligi mumkin (№29.4) — ilova ishlashiga ta'sir qilmaydi.
      debugPrint('push: qurilmani yozib bo\'lmadi: $e');
    }
  }

  Future<void> _showForeground(RemoteMessage m) async {
    final isChat = m.data['type'] == 'chat_message';
    // KP tayyor / holat o'zgardi — ekrandagi buyurtma darhol yangilansin, qo'lda tortish shart emas.
    if (!isChat) _ref.invalidate(myOrdersProvider);
    final n = m.notification;
    if (n == null) return;
    if (isChat) {
      // Suhbat ekranda ochiq bo'lsa — bildirishnoma kerak emas, xabar socketdan keladi.
      final id = int.tryParse('${m.data['chat_id'] ?? ''}');
      if (id != null && _ref.read(activeChatProvider) == id) return;
      _ref.read(chatsProvider.notifier).refresh();
    }
    final ch = isChat ? _chatChannel : _channel;
    await _local.show(
      id: isChat ? 'chat-${m.data['chat_id']}'.hashCode : m.hashCode,
      title: n.title,
      body: n.body,
      payload: jsonEncode(m.data),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          ch.id,
          ch.name,
          channelDescription: ch.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
          color: const Color(0xFF002854),
        ),
      ),
    );
  }

  void _openPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      _open(Map<String, dynamic>.from(jsonDecode(payload) as Map));
    } catch (_) {}
  }

  /// FCM `data`: `chat_id` → suhbat; `order_id` → buyurtma/KP sahifasi; `tracking_token` → kuzatish (hozircha saytda).
  void _open(Map<String, dynamic> data) {
    final chat = int.tryParse('${data['chat_id'] ?? ''}');
    if (data['type'] == 'chat_message' && chat != null) {
      _router?.push('/chat/$chat');
      return;
    }
    // Kuzatish endi ilovaning o'zida (№38): buyurtma raqami bo'lsa — buyurtma
    // sahifasi (xarita va bosqichlar shu yerda). Faqat token kelsa — sayt.
    final id = int.tryParse('${data['order_id'] ?? ''}');
    final tracking = '${data['tracking_token'] ?? ''}';
    if (id == null && RegExp(r'^[0-9a-f]{32}$').hasMatch(tracking)) {
      launchUrl(Uri.parse('${AppConfig.siteBase}/k/$tracking'), mode: LaunchMode.inAppBrowserView);
      return;
    }
    if (id == null) return;
    _ref.invalidate(myOrdersProvider); // ilova fonda turgan bo'lsa ro'yxat eski
    _router?.push('/order/$id');
  }
}

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref));
