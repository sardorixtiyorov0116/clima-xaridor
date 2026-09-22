import 'package:dio/dio.dart';

import '../config.dart';

/// Backend xatosi — ekranga chiqadigan turga keltirilgan.
class ApiException implements Exception {
  ApiException(this.kind, {this.message, this.status});

  final ApiErrorKind kind;

  /// Backend qaytargan matn (o'zbekcha). Faqat [ApiErrorKind.server4xx] da ishonchli.
  final String? message;
  final int? status;

  @override
  String toString() => 'ApiException($kind, $status, $message)';
}

enum ApiErrorKind { network, unauthorized, tooMany, server4xx, server5xx, unknown }

typedef TokenReader = String? Function();
typedef UnauthorizedHandler = void Function();

/// Yangi access token qaytaradi yoki null (refresh ham yaroqsiz — qayta kirish kerak).
/// Tarmoq xatosida istisno otadi — bunda foydalanuvchi chiqarilmaydi.
typedef TokenRefresher = Future<String?> Function();

/// Yagona HTTP klient. Token har so'rovda [readToken] dan olinadi —
/// sessiya almashsa klientni qayta yaratish shart emas.
class ApiClient {
  ApiClient({
    required TokenReader readToken,
    required UnauthorizedHandler onUnauthorized,
    TokenRefresher? refresh,
  })
      : _dio = Dio(BaseOptions(
          baseUrl: AppConfig.apiBase,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Accept': 'application/json', 'X-Client': 'climavent-app'},
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (o, h) {
        final t = readToken();
        if (o.extra['public'] == true) return h.next(o);
        if (t != null && !o.headers.containsKey('Authorization')) {
          o.headers['Authorization'] = 'Bearer $t';
        }
        h.next(o);
      },
      onError: (e, h) async {
        final o = e.requestOptions;
        final authed = o.headers.containsKey('Authorization');
        if (!authed || e.response?.statusCode != 401 || o.extra['retried'] == true) {
          return h.next(e);
        }
        // Access token eskirgan — foydalanuvchiga bildirmasdan yangilaymiz va so'rovni qaytaramiz.
        String? fresh;
        try {
          fresh = refresh == null ? null : await refresh();
        } catch (_) {
          // Internet yo'q yoki server javob bermadi — sessiya saqlanadi, faqat shu so'rov xato.
          return h.next(e);
        }
        if (fresh == null) {
          onUnauthorized();
          return h.next(e);
        }
        try {
          o.headers['Authorization'] = 'Bearer $fresh';
          o.extra['retried'] = true;
          h.resolve(await _dio.fetch<dynamic>(o));
        } on DioException catch (e2) {
          h.next(e2);
        }
      },
    ));
  }

  final Dio _dio;

  Future<Map<String, dynamic>> get(String path) => _send(() => _dio.get(path));

  /// Guvohnomasiz so'rov — katalog hamma uchun bir xil bo'lishi kerak.
  /// (Backend xaridor tokeni bilan yashirin do'konlar mahsulotlarini ham qaytaradi.)
  Future<Map<String, dynamic>> getPublic(String path) =>
      _send(() => _dio.get(path, options: Options(extra: {'public': true})));

  /// Tokensiz POST (refresh o'zi uchun — aylanib qolmasin).
  Future<Map<String, dynamic>> postNoAuth(String path, Object body) =>
      _send(() => _dio.post(path, data: body, options: Options(extra: {'public': true})));

  Future<Map<String, dynamic>> post(String path, Object body) =>
      _send(() => _dio.post(path, data: body));

  Future<Map<String, dynamic>> patch(String path, Object body) =>
      _send(() => _dio.patch(path, data: body));

  Future<Map<String, dynamic>> _send(Future<Response<dynamic>> Function() call) async {
    try {
      final r = await call();
      final d = r.data;
      if (d is Map<String, dynamic>) return d;
      return {'data': d};
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  static ApiException _map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ApiException(ApiErrorKind.network);
      default:
        break;
    }
    final status = e.response?.statusCode;
    final msg = _message(e.response?.data);
    if (status == null) return ApiException(ApiErrorKind.network);
    if (status == 401) return ApiException(ApiErrorKind.unauthorized, message: msg, status: status);
    if (status == 429) return ApiException(ApiErrorKind.tooMany, message: msg, status: status);
    if (status >= 500) return ApiException(ApiErrorKind.server5xx, status: status);
    return ApiException(ApiErrorKind.server4xx, message: msg, status: status);
  }

  static String? _message(Object? data) {
    if (data is Map) {
      final m = data['message'];
      if (m is String && m.trim().isNotEmpty) return m.trim();
      if (m is List && m.isNotEmpty) return m.first.toString();
    }
    return null;
  }
}
