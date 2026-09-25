import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/providers.dart';
import 'core/push/push_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/ui/name_screen.dart';
import 'features/auth/ui/otp_screen.dart';
import 'features/auth/ui/phone_screen.dart';
import 'features/catalog/ui/cart_tab.dart';
import 'features/catalog/ui/catalog_tab.dart';
import 'features/catalog/ui/category_screen.dart';
import 'features/catalog/ui/home_tab.dart';
import 'features/catalog/ui/product_screen.dart';
import 'features/catalog/ui/search_screen.dart';
import 'features/catalog/data/models.dart' show Store;
import 'features/chat/data/chat_models.dart';
import 'features/chat/ui/chat_screen.dart';
import 'features/chat/ui/chats_screen.dart';
import 'features/onboarding/language_screen.dart';
import 'features/orders/ui/checkout_done_screen.dart';
import 'features/orders/ui/checkout_screen.dart';
import 'features/orders/data/order_models.dart';
import 'features/orders/ui/order_screen.dart';
import 'features/orders/ui/orders_tab.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/home_shell.dart';
import 'features/shell/profile_tab.dart';
import 'features/services/ui/service_checkout_screen.dart';
import 'features/services/ui/service_screen.dart';
import 'features/services/ui/services_screen.dart';
import 'l10n/app_localizations.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final storage = ref.read(storageProvider);
  final firstLaunch = storage.locale == null;

  return GoRouter(
    initialLocation: firstLaunch
        ? '/language'
        : storage.onboarded
            ? '/home'
            : '/onboarding',
    routes: [
      GoRoute(path: '/language', builder: (_, _) => const LanguageScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(
        path: '/auth/phone',
        pageBuilder: (_, st) => _slide(
            st,
            PhoneScreen(
              firstRun: st.uri.queryParameters['first'] == '1',
              next: st.uri.queryParameters['next'],
            )),
      ),
      GoRoute(
        path: '/auth/otp',
        redirect: (_, st) => st.extra is OtpArgs ? null : '/auth/phone',
        pageBuilder: (_, st) => _slide(st, OtpScreen(args: st.extra! as OtpArgs)),
      ),
      GoRoute(
        path: '/auth/name',
        pageBuilder: (_, st) => _slide(st, NameScreen(next: st.uri.queryParameters['next'])),
      ),
      GoRoute(
        path: '/order/:id',
        pageBuilder: (_, st) => _slide(
            st,
            OrderScreen(
              orderId: int.tryParse(st.pathParameters['id'] ?? '') ?? 0,
              initial: st.extra is Order ? st.extra! as Order : null,
            )),
      ),
      GoRoute(
        path: '/checkout',
        pageBuilder: (_, st) => _slide(st, CheckoutScreen(kind: st.uri.queryParameters['kind'] ?? 'order')),
      ),
      GoRoute(
        path: '/checkout/done',
        pageBuilder: (_, st) => _fade(
            st,
            CheckoutDoneScreen(
              kind: st.uri.queryParameters['kind'] ?? 'order',
              ids: (st.uri.queryParameters['ids'] ?? '').split(',').where((e) => e.isNotEmpty).toList(),
            )),
      ),
      GoRoute(
        path: '/product/:id',
        pageBuilder: (_, st) =>
            _slide(st, ProductScreen(productId: int.tryParse(st.pathParameters['id'] ?? '') ?? 0)),
      ),
      GoRoute(
        path: '/category/:id',
        pageBuilder: (_, st) =>
            _slide(st, CategoryScreen(categoryId: int.tryParse(st.pathParameters['id'] ?? '') ?? 0)),
      ),
      GoRoute(path: '/chats', pageBuilder: (_, st) => _slide(st, const ChatsScreen())),
      // Xizmatlar (№39): katalog, xizmat sahifasi va buyurtma.
      GoRoute(
        path: '/services',
        pageBuilder: (_, st) => _slide(st, ServicesScreen(category: st.uri.queryParameters['c'])),
      ),
      GoRoute(
        path: '/service/:id',
        pageBuilder: (_, st) => _slide(
            st,
            ServiceScreen(
              serviceId: int.tryParse(st.pathParameters['id'] ?? '') ?? 0,
              variantId: int.tryParse(st.uri.queryParameters['v'] ?? ''),
            )),
      ),
      GoRoute(
        path: '/service/:id/book',
        pageBuilder: (_, st) => _slide(
            st,
            ServiceCheckoutScreen(
              serviceId: int.tryParse(st.pathParameters['id'] ?? '') ?? 0,
              variantId: int.tryParse(st.uri.queryParameters['v'] ?? '') ?? 0,
              qty: (int.tryParse(st.uri.queryParameters['q'] ?? '') ?? 1).clamp(1, 50),
            )),
      ),
      GoRoute(
        path: '/chat/store/:storeId',
        pageBuilder: (_, st) => _slide(
            st,
            ChatScreen(
              storeId: int.tryParse(st.pathParameters['storeId'] ?? '') ?? 0,
              productId: int.tryParse(st.uri.queryParameters['product'] ?? ''),
              store: st.extra is Store ? st.extra! as Store : null,
            )),
      ),
      GoRoute(
        path: '/chat/:id',
        pageBuilder: (_, st) => _slide(
            st,
            ChatScreen(
              chatId: int.tryParse(st.pathParameters['id'] ?? '') ?? 0,
              initial: st.extra is Chat ? st.extra! as Chat : null,
            )),
      ),
      GoRoute(path: '/search', pageBuilder: (_, st) => _fade(st, const SearchScreen())),
      GoRoute(path: '/favorites', pageBuilder: (_, st) => _slide(st, const FavoritesScreen())),
      // Faqat debug: dizaynni backendsiz ko'rish uchun.
      if (kDebugMode || const bool.fromEnvironment('DEV_ROUTES')) ...[
        GoRoute(
          path: '/dev/otp',
          builder: (_, _) => OtpScreen(
              args: OtpArgs(phone: '+998901234567', sent: CodeSent(verificationKey: 'dev', userId: '0'))),
        ),
        GoRoute(path: '/dev/consent', builder: (_, _) => const _DevConsent()),
      ],
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeTab())]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/catalog', builder: (_, _) => const CatalogTab()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/cart', builder: (_, _) => const CartTab()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/orders', builder: (_, _) => const OrdersTab()),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileTab())]),
        ],
      ),
    ],
  );
});

/// Auth ekranlari — iOS uslubidagi o'ngdan surilish.
CustomTransitionPage<void> _slide(GoRouterState st, Widget child) => CustomTransitionPage(
      key: st.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (_, a, sa, w) {
        final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
          child: SlideTransition(
            position: Tween(begin: Offset.zero, end: const Offset(-0.25, 0))
                .animate(CurvedAnimation(parent: sa, curve: Curves.easeOutCubic)),
            child: w,
          ),
        );
      },
    );

/// Qidiruv — yumshoq paydo bo'lish.
CustomTransitionPage<void> _fade(GoRouterState st, Widget child) => CustomTransitionPage(
      key: st.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (_, a, _, w) => FadeTransition(opacity: a, child: w),
    );

class ClimaventApp extends ConsumerWidget {
  const ClimaventApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Bir marta ishga tushadi (ichida himoya bor): bildirishnomalar va ularni bosganda sahifa ochish.
    ref.read(pushServiceProvider).init(router);
    return MaterialApp.router(
      title: 'Climavent',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (device, supported) {
        final code = device?.languageCode;
        return supported.firstWhere((l) => l.languageCode == code, orElse: () => const Locale('uz'));
      },
      builder: (context, child) {
        // Katta shrift sozlamasida ham tartib buzilmasin.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3)),
          child: ColoredBox(color: context.colors.background, child: child!),
        );
      },
    );
  }
}

class _DevConsent extends StatefulWidget {
  const _DevConsent();
  @override
  State<_DevConsent> createState() => _DevConsentState();
}

class _DevConsentState extends State<_DevConsent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => showConsentSheet(context));
  }

  @override
  Widget build(BuildContext context) => const PhoneScreen();
}
