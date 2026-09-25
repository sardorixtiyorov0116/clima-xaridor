import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../catalog/catalog_providers.dart';
import '../chat/chat_providers.dart';
import '../chat/chat_socket.dart';
import '../orders/orders_providers.dart';
import '../../l10n/app_localizations.dart';

/// Pastki menyu — 5 bo'lim, har biri o'z holatini saqlaydi.
///
/// Buyurtmalar socket signali (№36) bilan darhol yangilanadi — do'kon KP ga narx
/// yozsa, ochiq sahifada narx o'zi paydo bo'ladi. Zaxira: ilovaga qaytilganda va push kelganda.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late final AppLifecycleListener _life;
  final _subs = <StreamSubscription<Object?>>[];
  Timer? _debounce;

  StatefulNavigationShell get shell => widget.shell;

  @override
  void initState() {
    super.initState();
    _life = AppLifecycleListener(onResume: () => ref.invalidate(myOrdersProvider));
    final socket = ref.read(chatSocketProvider);
    _subs
      ..add(socket.orderUpdates.listen((_) => _reloadOrders()))
      // Uzilish (fon, internet) paytidagi signallar qayta kelmaydi.
      ..add(socket.reconnected.listen((_) => _reloadOrders()));
  }

  /// Bitta amal 2–3 signal berishi mumkin — 400 ms ichidagilar bitta yuklashga birlashadi.
  void _reloadOrders() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) ref.invalidate(myOrdersProvider);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final sub in _subs) {
      sub.cancel();
    }
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final cartCount = ref.watch(cartCountProvider);
    final unread = ref.watch(chatUnreadProvider);
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
                icon: Badge(isLabelVisible: unread > 0, child: const Icon(Icons.person_outline_rounded)),
                selectedIcon: Badge(isLabelVisible: unread > 0, child: const Icon(Icons.person_rounded)),
                label: s.tabProfile),
          ],
        ),
      ),
    ),
    );
  }
}
