import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../catalog/catalog_providers.dart';
import '../../l10n/app_localizations.dart';

/// Pastki menyu — 5 bo'lim, har biri o'z holatini saqlaydi.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final c = context.colors;
    final cartCount = ref.watch(cartCountProvider);
    // "Orqaga" (tugma yoki chetdan surish): boshqa bo'limda — Bosh sahifaga, Bosh sahifada — ilovadan chiqish.
    // go_router bo'limlar orasida PopScope ni hisobga olmaydi, shuning uchun router darajasida tinglaymiz.
    return BackButtonListener(
      onBackButtonPressed: () async {
        final onTop = ModalRoute.of(context)?.isCurrent ?? true; // ustida mahsulot sahifasi bo'lsa — u yopilsin
        if (!onTop || shell.currentIndex == 0) return false;
        HapticFeedback.selectionClick();
        shell.goBranch(0);
        return true;
      },
      child: Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) {
            HapticFeedback.selectionClick();
            shell.goBranch(i, initialLocation: i == shell.currentIndex);
          },
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: s.tabHome),
            NavigationDestination(
                icon: const Icon(Icons.grid_view_outlined),
                selectedIcon: const Icon(Icons.grid_view_rounded),
                label: s.tabCatalog),
            NavigationDestination(
                icon: Badge(
                    isLabelVisible: cartCount > 0,
                    label: Text('$cartCount'),
                    child: const Icon(Icons.shopping_cart_outlined)),
                selectedIcon: Badge(
                    isLabelVisible: cartCount > 0,
                    label: Text('$cartCount'),
                    child: const Icon(Icons.shopping_cart_rounded)),
                label: s.tabCart),
            NavigationDestination(
                icon: const Icon(Icons.receipt_long_outlined),
                selectedIcon: const Icon(Icons.receipt_long_rounded),
                label: s.tabOrders),
            NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: const Icon(Icons.person_rounded),
                label: s.tabProfile),
          ],
        ),
      ),
    ),
    );
  }
}
