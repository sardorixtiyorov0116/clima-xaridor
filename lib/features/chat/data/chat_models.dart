import '../../catalog/data/models.dart' show L10nText;

int _i(Object? v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
String? _s(Object? v) {
  final t = v?.toString().trim() ?? '';
  return t.isEmpty || t == 'null' ? null : t;
}

DateTime _d(Object? v) => DateTime.tryParse('${v ?? ''}')?.toLocal() ?? DateTime.now();

/// Suhbatdagi do'kon (xaridor uni ko'radi).
class ChatStore {
  const ChatStore({required this.id, required this.name, this.logoUrl});
  final int id;
  final String name;
  final String? logoUrl;

  static ChatStore fromJson(Object? o) {
    final m = o is Map ? o : const {};
    return ChatStore(id: _i(m['id']), name: _s(m['name']) ?? '', logoUrl: _s(m['logo_url']));
  }
}

/// Xabarga biriktirilgan mahsulot — qisqa ko'rinish.
class ChatProduct {
  const ChatProduct({required this.id, required this.name, this.image});
  final int id;
  final L10nText name;
  final String? image;

  static ChatProduct? fromJson(Object? o) {
    if (o is! Map<String, dynamic>) return null;
    return ChatProduct(id: _i(o['id']), name: L10nText.from(o, 'name'), image: _s(o['image']));
  }
}

enum SendState { sent, sending, failed }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.mine,
    required this.text,
    required this.createdAt,
    this.product,
    this.clientMsgId,
    this.state = SendState.sent,
  });

  /// Yuborilmagan xabarda 0.
  final int id;
  final int chatId;

  /// Xaridorning o'zi yozganmi.
  final bool mine;
  final String text;
  final ChatProduct? product;
  final String? clientMsgId;
  final DateTime createdAt;
  final SendState state;

  static ChatMessage fromJson(Map<String, dynamic> j) => ChatMessage(
    id: _i(j['id']),
    chatId: _i(j['chat_id']),
    mine: j['sender'] == 'client',
    text: _s(j['text']) ?? '',
    product: ChatProduct.fromJson(j['product']),
    clientMsgId: _s(j['client_msg_id']),
    createdAt: _d(j['created_at']),
  );

  ChatMessage copyWith({SendState? state}) => ChatMessage(
    id: id,
    chatId: chatId,
    mine: mine,
    text: text,
    product: product,
    clientMsgId: clientMsgId,
    createdAt: createdAt,
    state: state ?? this.state,
  );

  /// Bir xil xabarmi (serverdan kelgan va ilovada kutayotgan nusxasi).
  bool sameAs(ChatMessage o) => (id != 0 && id == o.id) || (clientMsgId != null && clientMsgId == o.clientMsgId);
}

class Chat {
  const Chat({
    required this.id,
    required this.store,
    required this.updatedAt,
    this.lastMessage,
    this.unread = 0,
    this.peerLastReadId = 0,
  });
  final int id;
  final ChatStore store;
  final ChatMessage? lastMessage;
  final int unread;

  /// Do'kon o'qigan oxirgi xabar — o'z xabarlariga ✓✓ shundan.
  final int peerLastReadId;
  final DateTime updatedAt;

  static Chat fromJson(Map<String, dynamic> j) {
    final last = j['last_message'];
    return Chat(
      id: _i(j['id']),
      store: ChatStore.fromJson(j['store']),
      lastMessage: last is Map<String, dynamic> ? ChatMessage.fromJson(last) : null,
      unread: _i(j['unread']),
      peerLastReadId: _i(j['peer_last_read_id']),
      updatedAt: _d(j['updated_at']),
    );
  }

  Chat copyWith({ChatMessage? lastMessage, int? unread, int? peerLastReadId, DateTime? updatedAt}) => Chat(
    id: id,
    store: store,
    lastMessage: lastMessage ?? this.lastMessage,
    unread: unread ?? this.unread,
    peerLastReadId: peerLastReadId ?? this.peerLastReadId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// Socketdan keladigan hodisalar.
sealed class ChatEvent {
  const ChatEvent(this.chatId);
  final int chatId;
}

class ChatMessageEvent extends ChatEvent {
  const ChatMessageEvent(super.chatId, this.message, this.chat);
  final ChatMessage message;

  /// Server yuborsa — ro'yxatdagi suhbatni to'liq almashtiramiz.
  final Chat? chat;
}

class ChatReadEvent extends ChatEvent {
  const ChatReadEvent(super.chatId, this.lastMessageId);
  final int lastMessageId;
}

class ChatTypingEvent extends ChatEvent {
  const ChatTypingEvent(super.chatId);
}
