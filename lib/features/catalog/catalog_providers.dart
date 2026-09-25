import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/catalog_repository.dart';
import 'data/models.dart';

final catalogRepositoryProvider =
    Provider<CatalogRepository>((ref) => CatalogRepository(ref.read(apiClientProvider)));

final categoriesProvider = FutureProvider<List<Category>>(
    (ref) => ref.read(catalogRepositoryProvider).categories());

final productsProvider =
    FutureProvider<List<Product>>((ref) => ref.read(catalogRepositoryProvider).products());

/// Do'konlarning to'liq rekvizitlari — KP blanki shu yerdan oladi.
final storesProvider =
    FutureProvider<List<Store>>((ref) => ref.read(catalogRepositoryProvider).stores());

final bannersProvider =
    FutureProvider<List<PromoBanner>>((ref) => ref.read(catalogRepositoryProvider).banners());

final usdRateProvider = FutureProvider<UsdRate>((ref) => ref.read(catalogRepositoryProvider).usdRate());

final productDetailProvider =
    FutureProvider.family<Product, int>((ref, id) => ref.read(catalogRepositoryProvider).product(id));

final htmlProvider =
    FutureProvider.family<String?, String>((ref, url) => ref.read(catalogRepositoryProvider).html(url));

/// Tanlangan til kodi (uz/ru/en) — modellardagi matnni tanlash uchun.
final langProvider = Provider<String>((ref) => ref.watch(localeProvider)?.languageCode ?? 'uz');

/// Kategoriya va uning barcha ichki kategoriyalari id lari.
Set<int> categoryWithChildren(List<Category> all, int id) {
  final out = {id};
  var added = true;
  while (added) {
    added = false;
    for (final c in all) {
      if (c.parentId != null && out.contains(c.parentId) && out.add(c.id)) added = true;
    }
  }
  return out;
}

// ── Sevimlilar (qurilmada) ──
class FavoritesController extends Notifier<Set<int>> {
  static const _key = 'favorites';

  @override
  Set<int> build() =>
      ref.read(storageProvider).list(_key).map(int.tryParse).whereType<int>().toSet();

  void toggle(int id) {
    final next = {...state};
    if (!next.remove(id)) next.add(id);
    state = next;
    ref.read(storageProvider).setList(_key, next.map((e) => '$e').toList());
  }
}

final favoritesProvider = NotifierProvider<FavoritesController, Set<int>>(FavoritesController.new);

String cartKey(int productId, int? modelId, int? variantId) =>
    '$productId:${modelId ?? 0}:${variantId ?? 0}';

// ── Savat (qurilmada; rasmiylashtirish keyingi bosqichda backend savatiga o'tadi) ──
class CartLine {
  const CartLine({required this.productId, required this.modelId, required this.qty, this.variantId, this.label});
  final int productId;

  /// null — mahsulotning modeli yo'q.
  final int? modelId;

  /// SAP varianti (model ichidagi aniq artikul), bo'lsa.
  final int? variantId;
  final int qty;

  /// Qo'shilgan paytdagi model/variant nomi (ro'yxat javobida variant nomlari yo'q).
  final String? label;

  String get key => cartKey(productId, modelId, variantId);

  CartLine copyWith({int? qty}) =>
      CartLine(productId: productId, modelId: modelId, variantId: variantId, label: label, qty: qty ?? this.qty);

  Map<String, Object?> toJson() => {'p': productId, 'm': modelId, 'v': variantId, 'q': qty, 'l': label};

  static CartLine? fromJson(String s) {
    try {
      final j = jsonDecode(s) as Map<String, dynamic>;
      return CartLine(
          productId: j['p'] as int,
          modelId: j['m'] as int?,
          variantId: j['v'] as int?,
          label: j['l'] as String?,
          qty: (j['q'] as int).clamp(1, 999));
    } catch (_) {
      return null;
    }
  }
}

class CartController extends Notifier<List<CartLine>> {
  static const _key = 'cart_v1';

  @override
  List<CartLine> build() =>
      ref.read(storageProvider).list(_key).map(CartLine.fromJson).whereType<CartLine>().toList();

  void _save(List<CartLine> v) {
    state = v;
    ref.read(storageProvider).setList(_key, v.map((l) => jsonEncode(l.toJson())).toList());
  }

  void add(int productId, int? modelId, {int? variantId, String? label, int qty = 1}) {
    final k = cartKey(productId, modelId, variantId);
    final i = state.indexWhere((l) => l.key == k);
    if (i < 0) {
      _save([
        ...state,
        CartLine(productId: productId, modelId: modelId, variantId: variantId, label: label, qty: qty),
      ]);
    } else {
      setQty(k, state[i].qty + qty);
    }
  }

  void setQty(String key, int qty) {
    if (qty <= 0) return remove(key);
    _save([for (final l in state) l.key == key ? l.copyWith(qty: qty.clamp(1, 999)) : l]);
  }

  void remove(String key) => _save(state.where((l) => l.key != key).toList());

  void clear() => _save(const []);
}

final cartProvider = NotifierProvider<CartController, List<CartLine>>(CartController.new);

final cartCountProvider = Provider<int>((ref) => ref.watch(cartProvider).fold(0, (a, l) => a + l.qty));

// ── Qidiruv tarixi ──
class SearchHistoryController extends Notifier<List<String>> {
  static const _key = 'search_history';

  @override
  List<String> build() => ref.read(storageProvider).list(_key);

  void push(String q) {
    final t = q.trim();
    if (t.length < 2) return;
    final next = [t, ...state.where((e) => e.toLowerCase() != t.toLowerCase())].take(8).toList();
    state = next;
    ref.read(storageProvider).setList(_key, next);
  }

  void clear() {
    state = const [];
    ref.read(storageProvider).setList(_key, const []);
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryController, List<String>>(SearchHistoryController.new);
