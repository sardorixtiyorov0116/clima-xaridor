import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'core/providers.dart';
import 'core/push/push_service.dart';
import 'core/storage/app_storage.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Native ochilish ekrani sessiya o'qilguncha turadi — oq miltillash bo'lmaydi.
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  GoogleFonts.config.allowRuntimeFetching = true;

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Push (Firebase, android/app/google-services.json). Xato bo'lsa ham ilova ishlayveradi.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  } catch (e) {
    debugPrint('firebase: $e');
  }

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
