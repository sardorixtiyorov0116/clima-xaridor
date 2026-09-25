import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/providers.dart';
import 'data/service_models.dart';

/// Xizmatlar katalogi (№39). Katalog so'rovlari tokensiz — mahsulotlar kabi,
/// hamma uchun bir xil.
class ServiceRepository {
  ServiceRepository(this._api);
  final ApiClient _api;

  static List<Map<String, dynamic>> _list(Map<String, dynamic> r) {
    final raw = r['rows'] ?? r['data'] ?? r['items'];
    return [for (final e in (raw is List ? raw : const [])) if (e is Map) Map<String, dynamic>.from(e)];
  }

  static String _q(Map<String, Object?> p) {
    final e = p.entries.where((e) => e.value != null && '${e.value}'.isNotEmpty);
    return e.isEmpty ? '' : '?${e.map((e) => '${e.key}=${Uri.encodeQueryComponent('${e.value}')}').join('&')}';
  }

  Future<List<ServiceCategory>> categories() async =>
      _list(await _api.getPublic('/service-categories')).map(ServiceCategory.fromJson).toList();

  Future<List<Region>> regions() async => _list(await _api.getPublic('/regions')).map(Region.fromJson).toList();

  Future<List<ServiceOffer>> services({String? category, ServiceArea? area, String sort = 'rating'}) async =>
      _list(await _api.getPublic('/services${_q({
        'category': category,
        'region': area?.region,
        'district': area?.district,
        'sort': sort,
        'limit': 100,
      })}'))
          .map(ServiceOffer.fromJson)
          .toList();

  Future<ServiceOffer> service(int id) async {
    final r = await _api.getPublic('/services/$id');
    return ServiceOffer.fromJson(r['service'] is Map ? Map<String, dynamic>.from(r['service'] as Map) : r);
  }

  /// Tovarga mos xizmatlar: shu tovarni sotayotgan do'konniki birinchi (`recommended`).
  Future<List<ServiceOffer>> forProduct(int productId, {ServiceArea? area}) async =>
      _list(await _api.getPublic('/products/$productId/services${_q({
        'region': area?.region,
        'district': area?.district,
      })}'))
          .map(ServiceOffer.fromJson)
          .toList();
}

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) => ServiceRepository(ref.read(apiClientProvider)));

final serviceCategoriesProvider =
    FutureProvider<List<ServiceCategory>>((ref) => ref.read(serviceRepositoryProvider).categories());

final regionsProvider = FutureProvider<List<Region>>((ref) => ref.read(serviceRepositoryProvider).regions());

/// Mijozning xizmat hududi — telefon xotirasida. Standart: Toshkent shahri.
class ServiceAreaController extends Notifier<ServiceArea> {
  static const _key = 'service_area';

  @override
  ServiceArea build() =>
      ServiceArea.fromStorage(ref.read(storageProvider).list(_key).firstOrNull) ??
      const ServiceArea(region: 'tashkent_city');

  void set(ServiceArea a) {
    state = a;
    ref.read(storageProvider).setList(_key, [a.toStorage()]);
  }
}

final serviceAreaProvider = NotifierProvider<ServiceAreaController, ServiceArea>(ServiceAreaController.new);

/// Tanlangan tur (`null` — hammasi) va hudud bo'yicha xizmatlar.
final servicesProvider = FutureProvider.family<List<ServiceOffer>, String?>((ref, category) {
  final area = ref.watch(serviceAreaProvider);
  return ref.read(serviceRepositoryProvider).services(category: category, area: area);
});

final serviceDetailProvider =
    FutureProvider.family<ServiceOffer, int>((ref, id) => ref.read(serviceRepositoryProvider).service(id));

/// Savat va rasmiylashtirish uchun: tovarga mos xizmatlar (hudud filtrisiz —
/// hudud rasmiylashtirishda tanlanadi, backend u yerda yana tekshiradi).
final productServicesProvider = FutureProvider.family<List<ServiceOffer>, int>(
  (ref, productId) => ref.read(serviceRepositoryProvider).forProduct(productId).catchError((_) => <ServiceOffer>[]),
);
