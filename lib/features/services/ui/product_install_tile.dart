import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../data/service_models.dart';
import '../services_providers.dart';
import 'service_widgets.dart';

/// Mahsulot sahifasida: shu tovarga mos o'rnatish xizmati bo'lsa — narxi bilan
/// ko'rsatiladi. Birinchi — tovarni sotayotgan do'konning o'z xizmati.
class ProductInstallTile extends ConsumerWidget {
  const ProductInstallTile({super.key, required this.productId});
  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final c = context.colors;
    final list = ref.watch(productServicesProvider(productId)).value ?? const <ServiceOffer>[];
    final install = list.where((o) => o.category?.key == 'installation' || o.recommended).toList();
    if (install.isEmpty) return const SizedBox.shrink();
    final o = install.first;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, 0),
      child: Material(
        color: Brand.mist.withValues(alpha: dark ? 0.1 : 0.35),
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: () => context.push('/service/${o.id}${o.suggestedVariantId == null ? '' : '?v=${o.suggestedVariantId}'}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.build_rounded, color: dark ? Brand.sky : Brand.navy, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.installTitle, style: context.text.titleMedium),
                      Text(
                        [
                          servicePriceText(context, o, variant: o.suggestedVariant),
                          if (o.warrantyMonths > 0) s.serviceWarranty(o.warrantyMonths),
                        ].join(' · '),
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
