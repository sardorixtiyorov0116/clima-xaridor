import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'core/providers.dart';
import 'core/storage/app_storage.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Native ochilish ekrani sessiya o'qilguncha turadi — oq miltillash bo'lmaydi.
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  GoogleFonts.config.allowRuntimeFetching = true;

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final storage = await AppStorage.open();
  final session = await storage.readSession();

  runApp(ProviderScope(
    overrides: [
      storageProvider.overrideWithValue(storage),
      initialSessionProvider.overrideWithValue(session),
    ],
    child: const ClimaventApp(),
  ));
  FlutterNativeSplash.remove();
}
