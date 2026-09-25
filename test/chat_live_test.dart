// Chatni №34 bo'yicha soxta backendga qarshi tekshirish (tarmoq kerak):
//   agentlar-tizimi/docs/backend-topshiriq-34-namuna-server.js ni alohida papkaga ko'chirib,
//   `npm i socket.io@4 && node server.js` (port 3999), keyin:
//   CHAT_LIVE=1 flutter test test/chat_live_test.dart --dart-define=API_BASE=http://127.0.0.1:3999/api
import 'dart:async';
import 'dart:io';

import 'package:climavent/core/config.dart';
import 'package:climavent/core/providers.dart';
import 'package:climavent/features/auth/data/session.dart';
import 'package:climavent/features/chat/chat_providers.dart';
import 'package:climavent/features/chat/chat_socket.dart';
import 'package:climavent/features/chat/data/chat_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

// Faqat mahalliy soxta serverga — production'ga hech qachon.
final _live = Platform.environment['CHAT_LIVE'] == '1' && AppConfig.apiBase.contains('127.0.0.1');

Future<T> _wait<T>(Future<T> f) => f.timeout(const Duration(seconds: 8));

Future<void> _until(bool Function() ok) async {
  final end = DateTime.now().add(const Duration(seconds: 8));
  while (!ok()) {
    if (DateTime.now().isAfter(end)) throw TimeoutException('shart bajarilmadi');
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null; // haqiqiy tarmoq

  test('xaridor ↔ do\'kon: REST + socket', skip: !_live, () async {
    final c = ProviderContainer(
      overrides: [
        initialSessionProvider.overrideWithValue(
          const Session(userId: '88', accessToken: 'client-88', phone: '+998901234567'),
        ),
      ],
    );
    addTearDown(c.dispose);
    final repo = c.read(chatRepositoryProvider);
    final run = DateTime.now().microsecondsSinceEpoch; // server holati qayta ishga tushirishda to'qnashmasin

    // 1. Suhbat ochish — ikkinchi marta o'sha id.
    final chat = await _wait(repo.open(2));
    expect(chat.store.name, 'Jihozvent');
    expect((await repo.open(2)).id, chat.id);

    // 2. Xaridor socketi ulanadi.
    final socket = c.read(chatSocketProvider);
    final events = <ChatEvent>[];
    socket.events.listen(events.add);
    await _until(() => socket.connected.value);

    // Do'kon tomoni — alohida socket va REST.
    final storeGot = <String, List<Map>>{'message': [], 'read': [], 'typing': []};
    final store = io.io(
      '${AppConfig.socketBase}/chat',
      io.OptionBuilder().setTransports(['websocket']).setAuth({'token': 'store-2'}).enableForceNew().build(),
    );
    for (final e in storeGot.keys) {
      store.on(e, (d) => storeGot[e]!.add(d as Map));
    }
    addTearDown(store.dispose);
    await _until(() => store.connected);
    final storeApi = Dio(BaseOptions(baseUrl: AppConfig.apiBase, headers: {'Authorization': 'Bearer store-2'}));

    // 3. Xaridor mahsulot bilan yozadi → do'konga socketda keladi.
    final sent = await repo.send(chat.id, text: 'Narxi qancha?', productId: 158, clientMsgId: 'm-$run');
    expect(sent.mine, isTrue);
    expect(sent.product?.id, 158);
    await _until(() => storeGot['message']!.isNotEmpty);
    expect(storeGot['message']!.last['message']['sender'], 'client');

    // Idempotent: o'sha client_msg_id — o'sha xabar.
    expect((await repo.send(chat.id, text: 'Narxi qancha?', clientMsgId: 'm-$run')).id, sent.id);

    // 4. Ro'yxat socketdan yangilanadi: do'kon javobi → unread 1.
    final sub = c.listen(chatsProvider, (_, _) {});
    addTearDown(sub.close);
    await _wait(c.read(chatsProvider.future));
    await storeApi.post('/chats/${chat.id}/messages', data: {'text': 'Salom! 450 \$', 'client_msg_id': 's-$run'});
    await _until(() => events.whereType<ChatMessageEvent>().any((e) => !e.message.mine));
    final got = events.whereType<ChatMessageEvent>().firstWhere((e) => !e.message.mine);
    expect(got.message.text, 'Salom! 450 \$');
    await _until(() => c.read(chatUnreadProvider) >= 1);
    expect(c.read(chatsProvider).value!.first.lastMessage?.text, 'Salom! 450 \$');

    // 5. Yozmoqda… (do'kondan) → xaridorda typing; xaridornikini do'kon oladi.
    store.emit('typing', {'chat_id': chat.id});
    await _until(() => events.whereType<ChatTypingEvent>().isNotEmpty);
    socket.typing(chat.id);
    await _until(() => storeGot['typing']!.isNotEmpty);

    // 6. O'qildi: xaridor → do'konga `read`; do'kon → xaridorga ChatReadEvent.
    await repo.markRead(chat.id, got.message.id);
    await _until(() => storeGot['read']!.isNotEmpty);
    expect(storeGot['read']!.first['reader'], 'client');
    await storeApi.post('/chats/${chat.id}/read', data: {'last_message_id': sent.id});
    await _until(() => events.whereType<ChatReadEvent>().isNotEmpty);
    expect(events.whereType<ChatReadEvent>().first.lastMessageId, sent.id);

    // 7. Xabarlar sahifasi — yangidan eskiga, peer_last_read_id bilan.
    final page = await repo.messages(chat.id);
    expect(page.items.first.id, greaterThan(page.items.last.id));
    // Do'kon javob yozgani uchun uning o'qigani o'z xabarigacha surilgan (№34, 2-band).
    expect(page.peerLastReadId, got.message.id);
  });

  test('yaroqsiz token — connect_error ichida "unauthorized"', skip: !_live, () async {
    final err = Completer<Object?>();
    final s = io.io(
      '${AppConfig.socketBase}/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': 'bad'})
          .enableForceNew()
          .disableReconnection()
          .build(),
    );
    s.onConnectError((e) {
      if (!err.isCompleted) err.complete(e);
    });
    addTearDown(s.dispose);
    expect('${await _wait(err.future)}', contains('unauthorized'));
  });
}
