import '../../../core/api/api_client.dart';
import 'chat_models.dart';

/// Chat REST qismi (backend №34). Yuborish REST orqali, qabul qilish — socketda.
class ChatRepository {
  ChatRepository(this._api);
  final ApiClient _api;

  static List<Map<String, dynamic>> _list(Map<String, dynamic> r) => [
    for (final e in (r['data'] as List? ?? const []))
      if (e is Map<String, dynamic>) e,
  ];

  static Map<String, dynamic> _obj(Map<String, dynamic> r) =>
      r['data'] is Map<String, dynamic> ? r['data'] as Map<String, dynamic> : r;

  /// Do'kon bilan suhbat — bor bo'lsa o'sha, yo'q bo'lsa yangisi.
  Future<Chat> open(int storeId) async => Chat.fromJson(_obj(await _api.post('/chats', {'store_id': storeId})));

  Future<List<Chat>> chats() async => [for (final j in _list(await _api.get('/chats'))) Chat.fromJson(j)];

  Future<Chat> chat(int id) async {
    final all = await chats();
    return all.firstWhere((c) => c.id == id, orElse: () => throw ApiException(ApiErrorKind.server4xx, status: 404));
  }

  /// Yangidan eskiga. [beforeId] — undan eskilari.
  Future<({List<ChatMessage> items, int peerLastReadId})> messages(int chatId, {int? beforeId, int limit = 30}) async {
    final q = beforeId == null ? '' : '&before_id=$beforeId';
    final r = await _api.get('/chats/$chatId/messages?limit=$limit$q');
    return (
      items: [for (final j in _list(r)) ChatMessage.fromJson(j)],
      peerLastReadId: int.tryParse('${r['peer_last_read_id'] ?? ''}') ?? 0,
    );
  }

  Future<ChatMessage> send(int chatId, {required String text, int? productId, required String clientMsgId}) async =>
      ChatMessage.fromJson(
        _obj(
          await _api.post('/chats/$chatId/messages', {
            'text': text,
            'product_id': ?productId,
            'client_msg_id': clientMsgId,
          }),
        ),
      );

  Future<void> markRead(int chatId, int lastMessageId) async {
    await _api.post('/chats/$chatId/read', {'last_message_id': lastMessageId});
  }
}
