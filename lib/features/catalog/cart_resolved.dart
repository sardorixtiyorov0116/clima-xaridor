import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catalog_providers.dart';
import 'data/models.dart';

/// Savat qatori + katalogdagi mahsulot, model va variant.
class ResolvedLine {
  ResolvedLine(this.line, this.product, this.model, this.variant);
  final CartLine line;
  final Product product;
  final ProductModel? model;
  final Variant? variant;

  Price? get price {
    if (variant != null) return variant!.price ?? model?.price;
    if (model != null) return model!.price;
    if (product.models.isEmpty && product.minUsd != null) {
      return Price(product.minUsd!, saleUsd: product.minSaleUsd, uzs: product.minUzs, saleUzs: product.minSaleUzs);
    }
    return null;
  }

  /// Buyurtmada ko'rinadigan model nomi: variant kodi > model nomi > mahsulot id.
  String get modelTitle {
    final code = variant?.code ?? '';
    if (code.isNotEmpty) return code;
    if ((line.label ?? '').isNotEmpty) return line.label!;
    if (model != null) return model!.title;
    return '${product.id}';
  }

  /// Savatda ko'rsatiladigan ikkinchi qator.
  String? get subtitle {
    final name = variant?.name ?? '';
    if (name.isNotEmpty) return name;
    if ((line.label ?? '').isNotEmpty) return line.label;
    return model?.title;
  }
}

final resolvedCartProvider = Provider<List<ResolvedLine>>((ref) {
  final lines = ref.watch(cartProvider);
  final all = ref.watch(productsProvider).value ?? const <Product>[];
  final out = <ResolvedLine>[];
  for (final l in lines) {
    final p = all.where((x) => x.id == l.productId).firstOrNull;
    if (p == null) continue;
    final m = p.models.where((x) => x.id == l.modelId).firstOrNull;
    final v = m?.variants.where((x) => x.id == l.variantId).firstOrNull;
    out.add(ResolvedLine(l, p, m, v));
  }
  return out;
});
