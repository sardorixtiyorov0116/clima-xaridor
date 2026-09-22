# Climavent — xaridor ilovasi (Flutter)

Android va iOS uchun. 1-bosqich: poydevor, dizayn tizimi, kirish va ro'yxatdan o'tish.

## Ishga tushirish

```bash
flutter pub get
flutter run
```

APK: `flutter build apk --release --split-per-abi` → `build/app/outputs/flutter-apk/`.
Ko'pchilik telefon uchun `app-arm64-v8a-release.apk`.

Boshqa backend: `--dart-define=API_BASE=https://.../api`.

## Tuzilma

```
lib/
  core/        config, API klient (dio), xotira, providerlar (riverpod), mavzu, umumiy vidjetlar
  features/
    onboarding/  til tanlash, 3 ta tanishtiruv sahifasi
    auth/        telefon → rozilik (yangi raqam) → SMS-kod → ism
    shell/       pastki menyu: Bosh sahifa, Katalog, Savat, Buyurtmalar, Profil
  l10n/        uz (asosiy), ru, en — ARB fayllar, `flutter gen-l10n`
```

## Kirish oqimi (backend bilan sayt kabi)

1. `POST /users/login` `{phone_number, check_consent: true}` →
   `consent_required` (yangi raqam, SMS ketmaydi) yoki `otpinfo.details` + `user.id`.
2. Yangi raqam — rozilik oynasi, keyin login `terms_version` / `privacy_version` bilan qayta.
3. `POST /users/verify-otp` `{phone_number, verification_key, otp, userId}` → `client`, `tokens`.
4. Ism bo'sh bo'lsa — `PATCH /users/update/:id`.

Tokenlar Android Keystore / iOS Keychain'da (`flutter_secure_storage`). 401 — sessiya o'chadi.
Android'da SMS kodi **User Consent API** bilan o'qiladi (SMS shabloniga ilova xeshi shart emas),
raqam — Google'ning "raqamni tanlang" oynasi bilan.

## Imzo

`android/key.properties` va `android/climavent-upload.jks` — git'ga kirmaydi.
**Kalitning zaxira nusxasini saqlang**: yo'qolsa Play Market'da ilovani yangilab bo'lmaydi.
Fayllar yo'q bo'lsa release debug kalit bilan imzolanadi.

## Dizayn tekshiruvi (web)

`flutter build web --dart-define=DEV_ROUTES=true` — `/#/dev/otp` va `/#/dev/consent`
sahifalari backendsiz ochiladi. Release APK'da bu marshrutlar yo'q.
