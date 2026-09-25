import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/config.dart';
import '../../core/providers.dart';
import 'data/chat_models.dart';

/// Chat va buyurtma signallari socketi (backend №34 + №36, `/chat` namespace).
/// - kirgan va ilova ochiq bo'lsa ulanadi, fonga o'tsa uziladi (u holda xabar push bo'lib keladi);
/// - token eskirsa (`unauthorized`) yangilab, qayta ulanadi;
/// - hodisalar [events] oqimiga tushadi.
class ChatSocket {
  ChatSocket(this._ref) {
    _ref.listen(sessionProvider, (prev, next) {
      if (prev?.accessToken == next?.accessToken) return;
      _reconnect();
    });
    _life = AppLifecycleListener(
      onResume: () {
        _foreground = true;
        _reconnect();
      },
      onHide: () {
        _foreground = false;
        _disconnect();
      },
    );
    _reconnect();
  }

  final Ref _ref;
  late final AppLifecycleListener _life;
  io.Socket? _socket;
  bool _foreground = true;
  bool _refreshing = false;
  bool _everConnected = false;
  DateTime _lastTyping = DateTime(2000);

  final _events = StreamController<ChatEvent>.broadcast();
  Stream<ChatEvent> get events => _events.stream;

  /// Ulanish holati — sarlavhada "ulanmoqda…" ko'rsatish uchun.
  final connected = ValueNotifier<bool>(false);

  /// Server `forbidden` dedi (superadmin, kuryer, chat ruxsati yo'q xodim — №34 javobi):
  /// token yangilash foyda bermaydi, "ulanmoqda…" ham ko'rsatilmaydi.
  bool forbidden = false;

  /// Qayta ulangach — ochiq suhbat yo'qotilgan xabarlarni qayta so'raydi.
  final _reconnected = StreamController<void>.broadcast();
  Stream<void> get reconnected => _reconnected.stream;

  /// Buyurtma o'zgardi (backend №36, `order_updated`) — faqat signal: buyurtma id si.
  /// Ma'lumot REST dan qayta olinadi. Uzilish paytidagi signallar qayta kelmaydi —
  /// shuning uchun [reconnected] da ham ro'yxat yangilanishi kerak.
  final _orders = StreamController<int>.broadcast();
  Stream<int> get orderUpdates => _orders.stream;

  void _reconnect() {
    _disconnect();
    forbidden = false;
    final token = _ref.read(sessionProvider)?.accessToken;
    if (token == null || !_foreground) return;
    final s = io.io(
      '${AppConfig.socketBase}/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableForceNew() // keshdagi eski ulanish (eski token bilan) qayta ishlatilmasin
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(10000)
          .build(),
    );
    s.onConnect((_) {
      connected.value = true;
      // Uzilish (fon, internet) paytida kelgan xabarlarni ochiq ekranlar qayta so'raydi.
      if (_everConnected) _reconnected.add(null);
      _everConnected = true;
    });
    s.onDisconnect((_) => connected.value = false);
    s.onConnectError((e) {
      connected.value = false;
      if ('$e'.contains('forbidden')) {
        forbidden = true;
        s.dispose(); // qayta urinish ma'nosiz
      } else if ('$e'.contains('unauthorized')) {
        _onUnauthorized();
      }
    });
    s.on('message', (d) {
      if (d is! Map) return;
      final m = Map<String, dynamic>.from(d);
      final msg = m['message'];
      final chat = m['chat'];
      if (msg is! Map) return;
      final message = ChatMessage.fromJson(Map<String, dynamic>.from(msg));
      _events.add(
        ChatMessageEvent(
          int.tryParse('${m['chat_id']}') ?? message.chatId,
          message,
          chat is Map ? Chat.fromJson(Map<String, dynamic>.from(chat)) : null,
        ),
      );
    });
    s.on('read', (d) {
      if (d is! Map || d['reader'] == 'client') return;
      _events.add(ChatReadEvent(int.tryParse('${d['chat_id']}') ?? 0, int.tryParse('${d['last_message_id']}') ?? 0));
    });
    s.on('typing', (d) {
      if (d is! Map || d['from'] == 'client') return;
      _events.add(ChatTypingEvent(int.tryParse('${d['chat_id']}') ?? 0));
    });
    s.on('order_updated', (d) {
      if (d is! Map) return;
      final id = int.tryParse('${d['order_id']}');
      debugPrint('socket: order_updated $id ${d['status']}');
      if (id != null) _orders.add(id);
    });
    _socket = s..connect();
  }

  /// Token eskirgan — HTTP dagi kabi jim yangilaymiz. Yangi token kelsa
  /// sessiya o'zgaradi va [_reconnect] o'zi ishlaydi.
  Future<void> _onUnauthorized() async {
    if (_refreshing) return;
    _refreshing = true;
    _disconnect();
    try {
      final fresh = await _ref.read(sessionProvider.notifier).refreshAccess();
      if (fresh == null) debugPrint('chat: sessiya yaroqsiz');
    } catch (_) {
      // Internet yo'q — biroz kutib qayta urinamiz.
      await Future<void>.delayed(const Duration(seconds: 5));
      _reconnect();
    } finally {
      _refreshing = false;
    }
  }

  void _disconnect() {
    final s = _socket;
    _socket = null;
    connected.value = false;
    s?.dispose();
  }

  /// "Yozmoqda…" — 3 soniyada bir martadan ko'p emas.
  void typing(int chatId) {
    final now = DateTime.now();
    if (now.difference(_lastTyping) < const Duration(seconds: 3)) return;
    _lastTyping = now;
    _socket?.emit('typing', {'chat_id': chatId});
  }

  void dispose() {
    _life.dispose();
    _disconnect();
    _events.close();
    _reconnected.close();
    _orders.close();
  }
}

final chatSocketProvider = Provider<ChatSocket>((ref) {
  final s = ChatSocket(ref);
  ref.onDispose(s.dispose);
  return s;
});
