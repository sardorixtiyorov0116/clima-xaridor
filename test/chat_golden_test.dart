// Chat ekranlarining rasmi (dizaynni ko'z bilan tekshirish uchun):
//   CHAT_GOLDEN=1 flutter test test/chat_golden_test.dart --update-goldens
// Rasmlar: test/goldens/*.png (git'ga qo'shilmaydi).
import 'dart:async';
import 'dart:io';

import 'package:climavent/core/providers.dart';
import 'package:climavent/core/theme/tokens.dart';
import 'package:climavent/features/catalog/catalog_providers.dart' show langProvider;
import 'package:climavent/features/auth/data/session.dart';
import 'package:climavent/features/catalog/data/models.dart' show L10nText;
import 'package:climavent/features/chat/chat_providers.dart';
import 'package:climavent/features/chat/chat_socket.dart';
import 'package:climavent/features/chat/data/chat_models.dart';
import 'package:climavent/features/chat/data/chat_repository.dart';
import 'package:climavent/features/chat/ui/chat_screen.dart';
import 'package:climavent/features/chat/ui/chats_screen.dart';
import 'package:climavent/features/catalog/ui/widgets.dart' show ErrorRetry;
import 'package:climavent/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _on = Platform.environment['CHAT_GOLDEN'] == '1';

class _FakeSocket implements ChatSocket {
  @override
  final connected = ValueNotifier(true);
  @override
  bool forbidden = false;
  @override
  Stream<ChatEvent> get events => const Stream.empty();
  @override
  Stream<void> get reconnected => const Stream.empty();
  @override
  void typing(int chatId) {}
  @override
  void dispose() {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

final _now = DateTime.now();
DateTime _ago(int minutes) => _now.subtract(Duration(minutes: minutes));
const _store = ChatStore(id: 2, name: 'Jihozvent');
const _product = ChatProduct(id: 158, name: L10nText('Konditsioner Midea MSAG-12HRN1', '', ''));

final _msgs = [
  ChatMessage(id: 306, chatId: 15, mine: true, text: 'Rahmat, KP soʻrayman', createdAt: _ago(2)),
  ChatMessage(
    id: 305,
    chatId: 15,
    mine: false,
    text: 'Ha, omborda 14 dona bor. 12 dona olsangiz narxni KP da chegirma bilan yozamiz.',
    createdAt: _ago(5),
  ),
  ChatMessage(id: 304, chatId: 15, mine: true, text: 'Omborda bormi? 12 dona kerak', createdAt: _ago(9)),
  ChatMessage(id: 303, chatId: 15, mine: true, text: 'Salom!', product: _product, createdAt: _ago(10)),
  ChatMessage(
    id: 0,
    chatId: 15,
    mine: true,
    text: 'Yetkazib berish Chilonzorga qancha?',
    clientMsgId: 'x',
    createdAt: _ago(1),
    state: SendState.failed,
  ),
];

final _chat = Chat(id: 15, store: _store, updatedAt: _ago(1), lastMessage: _msgs.first, peerLastReadId: 305);

class _FakeRepo implements ChatRepository {
  @override
  Future<List<Chat>> chats() async => [
    _chat,
    Chat(
      id: 16,
      store: const ChatStore(id: 3, name: 'Armavent'),
      updatedAt: _ago(60 * 26),
      unread: 2,
      lastMessage: ChatMessage(
        id: 290,
        chatId: 16,
        mine: false,
        text: 'Montaj narxi alohida hisoblanadi',
        createdAt: _ago(60 * 26),
      ),
    ),
  ];
  @override
  Future<({List<ChatMessage> items, int peerLastReadId})> messages(int chatId, {int? beforeId, int limit = 30}) async =>
      (items: _msgs.where((m) => m.id != 0).toList(), peerLastReadId: 305);
  @override
  Future<void> markRead(int chatId, int lastMessageId) async {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Future<void> _loadFonts() async {
  Future<ByteData> f(String p) async => ByteData.sublistView(await File(p).readAsBytes());
  final noto = FontLoader('Noto')
    ..addFont(f('assets/fonts/NotoSans-Regular.ttf'))
    ..addFont(f('assets/fonts/NotoSans-Bold.ttf'));
  await noto.load();
  final flutterRoot = File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
  final icons = FontLoader('MaterialIcons')
    ..addFont(f('$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf'));
  await icons.load();
}

Widget _app(Widget home, Brightness b, {ChatRepository? repo}) => ProviderScope(
  overrides: [
    initialSessionProvider.overrideWithValue(const Session(userId: '88', accessToken: 't', phone: '+998901234567')),
    chatSocketProvider.overrideWithValue(_FakeSocket()),
    chatRepositoryProvider.overrideWithValue(repo ?? _FakeRepo()),
    langProvider.overrideWithValue('uz'),
  ],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('uz'),
    supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(
      brightness: b,
      fontFamily: 'Noto',
      colorSchemeSeed: Brand.navy,
      extensions: [b == Brightness.dark ? AppColors.dark : AppColors.light],
      scaffoldBackgroundColor: (b == Brightness.dark ? AppColors.dark : AppColors.light).background,
    ),
    home: home,
  ),
);

void main() {
  setUpAll(_loadFonts);

  for (final b in Brightness.values) {
    testWidgets('suhbat ${b.name}', skip: !_on, (t) async {
      t.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await t.pumpWidget(_app(ChatScreen(chatId: 15, initial: _chat), b));
      await t.pumpAndSettle();
      for (final e in t.widgetList<ErrorRetry>(find.byType(ErrorRetry))) {
        // ignore: avoid_print
        print('XATO: ${e.error}');
      }
      await expectLater(find.byType(ChatScreen), matchesGoldenFile('goldens/chat_${b.name}.png'));
    });
  }

  testWidgets('suhbatlar ro\'yxati', skip: !_on, (t) async {
    t.view.physicalSize = const Size(390 * 2.0, 600 * 2.0);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(_app(const ChatsScreen(), Brightness.light));
    await t.pumpAndSettle();
    await expectLater(find.byType(ChatsScreen), matchesGoldenFile('goldens/chats.png'));
  });

  testWidgets('bo\'sh suhbat — tezkor savollar', skip: !_on, (t) async {
    t.view.physicalSize = const Size(390 * 2.0, 700 * 2.0);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final empty = Chat(id: 17, store: _store, updatedAt: _now);
    await t.pumpWidget(_app(ChatScreen(chatId: 17, initial: empty), Brightness.light, repo: _EmptyRepo()));
    await t.pumpAndSettle();
    await expectLater(find.byType(ChatScreen), matchesGoldenFile('goldens/chat_empty.png'));
  });
}

class _EmptyRepo extends _FakeRepo {
  @override
  Future<({List<ChatMessage> items, int peerLastReadId})> messages(int chatId, {int? beforeId, int limit = 30}) async =>
      (items: <ChatMessage>[], peerLastReadId: 0);
}
