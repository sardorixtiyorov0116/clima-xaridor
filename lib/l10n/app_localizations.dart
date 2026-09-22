import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
  ];

  /// No description provided for @appName.
  ///
  /// In uz, this message translates to:
  /// **'Climavent'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In uz, this message translates to:
  /// **'Ventilyatsiya va konditsioner uskunalari'**
  String get tagline;

  /// No description provided for @langTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tilni tanlang'**
  String get langTitle;

  /// No description provided for @langSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Keyinroq profil sozlamalarida oʻzgartirish mumkin'**
  String get langSubtitle;

  /// No description provided for @continueAction.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish'**
  String get continueAction;

  /// No description provided for @onb1Title.
  ///
  /// In uz, this message translates to:
  /// **'Ishlab chiqaruvchidan toʻgʻridan-toʻgʻri'**
  String get onb1Title;

  /// No description provided for @onb1Body.
  ///
  /// In uz, this message translates to:
  /// **'Ventilyatorlar, konditsionerlar, havo kanallari — Oʻzbekistondagi zavod va doʻkonlardan.'**
  String get onb1Body;

  /// No description provided for @onb2Title.
  ///
  /// In uz, this message translates to:
  /// **'Tijorat taklifi bir zumda'**
  String get onb2Title;

  /// No description provided for @onb2Body.
  ///
  /// In uz, this message translates to:
  /// **'Savatga soling va sotib olishdan oldin KP ni PDF qilib oling — rahbariyatga tasdiqlatish uchun.'**
  String get onb2Body;

  /// No description provided for @onb3Title.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazishni jonli kuzating'**
  String get onb3Title;

  /// No description provided for @onb3Body.
  ///
  /// In uz, this message translates to:
  /// **'Kuryer qayerda va qachon yetib kelishini xaritada koʻrasiz.'**
  String get onb3Body;

  /// No description provided for @onbNext.
  ///
  /// In uz, this message translates to:
  /// **'Keyingisi'**
  String get onbNext;

  /// No description provided for @onbStart.
  ///
  /// In uz, this message translates to:
  /// **'Boshlash'**
  String get onbStart;

  /// No description provided for @onbSkip.
  ///
  /// In uz, this message translates to:
  /// **'Oʻtkazib yuborish'**
  String get onbSkip;

  /// No description provided for @phoneTitle.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqamingiz'**
  String get phoneTitle;

  /// No description provided for @phoneSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Kirish yoki roʻyxatdan oʻtish uchun SMS orqali kod yuboramiz'**
  String get phoneSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqami'**
  String get phoneLabel;

  /// No description provided for @phoneInvalid.
  ///
  /// In uz, this message translates to:
  /// **'Raqamni toʻliq kiriting: 9 ta raqam'**
  String get phoneInvalid;

  /// No description provided for @getCode.
  ///
  /// In uz, this message translates to:
  /// **'Kodni olish'**
  String get getCode;

  /// No description provided for @later.
  ///
  /// In uz, this message translates to:
  /// **'Keyinroq'**
  String get later;

  /// No description provided for @phoneFooter.
  ///
  /// In uz, this message translates to:
  /// **'Davom etib, siz SMS olishga rozilik bildirasiz. Standart operator tarifi.'**
  String get phoneFooter;

  /// No description provided for @consentTitle.
  ///
  /// In uz, this message translates to:
  /// **'Siz bizda yangisiz'**
  String get consentTitle;

  /// No description provided for @consentBody.
  ///
  /// In uz, this message translates to:
  /// **'Hisob yaratish uchun shartlar bilan tanishib chiqing va rozilik bering.'**
  String get consentBody;

  /// No description provided for @consentPrefix.
  ///
  /// In uz, this message translates to:
  /// **'Men '**
  String get consentPrefix;

  /// No description provided for @consentTerms.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanish shartlari'**
  String get consentTerms;

  /// No description provided for @consentAnd.
  ///
  /// In uz, this message translates to:
  /// **' va '**
  String get consentAnd;

  /// No description provided for @consentPrivacy.
  ///
  /// In uz, this message translates to:
  /// **'Maxfiylik siyosati'**
  String get consentPrivacy;

  /// No description provided for @consentSuffix.
  ///
  /// In uz, this message translates to:
  /// **' bilan tanishdim va roziman'**
  String get consentSuffix;

  /// No description provided for @consentAccept.
  ///
  /// In uz, this message translates to:
  /// **'Roziman, kodni yuborish'**
  String get consentAccept;

  /// No description provided for @otpTitle.
  ///
  /// In uz, this message translates to:
  /// **'Kodni kiriting'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'{phone} raqamiga 5 xonali kod yubordik'**
  String otpSubtitle(String phone);

  /// No description provided for @otpChangeNumber.
  ///
  /// In uz, this message translates to:
  /// **'Raqamni oʻzgartirish'**
  String get otpChangeNumber;

  /// No description provided for @otpResendIn.
  ///
  /// In uz, this message translates to:
  /// **'Kodni qayta yuborish: {time}'**
  String otpResendIn(String time);

  /// No description provided for @otpResend.
  ///
  /// In uz, this message translates to:
  /// **'Kodni qayta yuborish'**
  String get otpResend;

  /// No description provided for @otpResent.
  ///
  /// In uz, this message translates to:
  /// **'Yangi kod yuborildi'**
  String get otpResent;

  /// No description provided for @otpWrong.
  ///
  /// In uz, this message translates to:
  /// **'Kod notoʻgʻri. Qaytadan urinib koʻring'**
  String get otpWrong;

  /// No description provided for @otpExpired.
  ///
  /// In uz, this message translates to:
  /// **'Kodning muddati tugadi. Yangisini soʻrang'**
  String get otpExpired;

  /// No description provided for @otpVerifying.
  ///
  /// In uz, this message translates to:
  /// **'Tekshirilmoqda…'**
  String get otpVerifying;

  /// No description provided for @profileSetupTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tanishib olaylik'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Ismingiz buyurtma va tijorat takliflarida koʻrsatiladi'**
  String get profileSetupSubtitle;

  /// No description provided for @firstName.
  ///
  /// In uz, this message translates to:
  /// **'Ism'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In uz, this message translates to:
  /// **'Familiya'**
  String get lastName;

  /// No description provided for @firstNameRequired.
  ///
  /// In uz, this message translates to:
  /// **'Ismingizni kiriting'**
  String get firstNameRequired;

  /// No description provided for @save.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get save;

  /// No description provided for @welcome.
  ///
  /// In uz, this message translates to:
  /// **'Xush kelibsiz, {name}!'**
  String welcome(String name);

  /// No description provided for @welcomeNoName.
  ///
  /// In uz, this message translates to:
  /// **'Xush kelibsiz!'**
  String get welcomeNoName;

  /// No description provided for @tabHome.
  ///
  /// In uz, this message translates to:
  /// **'Bosh sahifa'**
  String get tabHome;

  /// No description provided for @tabCatalog.
  ///
  /// In uz, this message translates to:
  /// **'Katalog'**
  String get tabCatalog;

  /// No description provided for @tabCart.
  ///
  /// In uz, this message translates to:
  /// **'Savat'**
  String get tabCart;

  /// No description provided for @tabOrders.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalar'**
  String get tabOrders;

  /// No description provided for @tabProfile.
  ///
  /// In uz, this message translates to:
  /// **'Profil'**
  String get tabProfile;

  /// No description provided for @searchHint.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot yoki model qidirish'**
  String get searchHint;

  /// No description provided for @soonTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tez orada'**
  String get soonTitle;

  /// No description provided for @soonCatalog.
  ///
  /// In uz, this message translates to:
  /// **'Katalog shu yerda boʻladi: mahsulotlar, modellar va filtrlar.'**
  String get soonCatalog;

  /// No description provided for @soonCart.
  ///
  /// In uz, this message translates to:
  /// **'Savatdan sotib olish yoki KP olish — ikkalasi ham bir tugmada.'**
  String get soonCart;

  /// No description provided for @soonOrders.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalar, KP lar va yetkazishni kuzatish shu yerda.'**
  String get soonOrders;

  /// No description provided for @homeHeroTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ilova ishga tushmoqda'**
  String get homeHeroTitle;

  /// No description provided for @homeHeroBody.
  ///
  /// In uz, this message translates to:
  /// **'Birinchi bosqich — kirish va hisob. Katalog, savat va kuzatish navbatda.'**
  String get homeHeroBody;

  /// No description provided for @guestTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hisobingizga kiring'**
  String get guestTitle;

  /// No description provided for @guestBody.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalar, tijorat takliflari va yetkazish holati bir joyda'**
  String get guestBody;

  /// No description provided for @signIn.
  ///
  /// In uz, this message translates to:
  /// **'Kirish'**
  String get signIn;

  /// No description provided for @settingsLanguage.
  ///
  /// In uz, this message translates to:
  /// **'Til'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In uz, this message translates to:
  /// **'Mavzu'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In uz, this message translates to:
  /// **'Tizim boʻyicha'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In uz, this message translates to:
  /// **'Yorugʻ'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In uz, this message translates to:
  /// **'Qorongʻi'**
  String get themeDark;

  /// No description provided for @settingsTerms.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanish shartlari'**
  String get settingsTerms;

  /// No description provided for @settingsPrivacy.
  ///
  /// In uz, this message translates to:
  /// **'Maxfiylik siyosati'**
  String get settingsPrivacy;

  /// No description provided for @settingsSupport.
  ///
  /// In uz, this message translates to:
  /// **'Qoʻllab-quvvatlash'**
  String get settingsSupport;

  /// No description provided for @signOut.
  ///
  /// In uz, this message translates to:
  /// **'Chiqish'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Hisobdan chiqasizmi?'**
  String get signOutConfirm;

  /// No description provided for @cancel.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get cancel;

  /// No description provided for @version.
  ///
  /// In uz, this message translates to:
  /// **'Versiya {v}'**
  String version(String v);

  /// No description provided for @errNetwork.
  ///
  /// In uz, this message translates to:
  /// **'Internet bilan aloqa yoʻq. Ulanishni tekshiring'**
  String get errNetwork;

  /// No description provided for @errServer.
  ///
  /// In uz, this message translates to:
  /// **'Serverda xatolik. Birozdan keyin urinib koʻring'**
  String get errServer;

  /// No description provided for @errTooMany.
  ///
  /// In uz, this message translates to:
  /// **'Urinishlar juda koʻp. Birozdan keyin qayta urinib koʻring'**
  String get errTooMany;

  /// No description provided for @errUnknown.
  ///
  /// In uz, this message translates to:
  /// **'Kutilmagan xatolik yuz berdi'**
  String get errUnknown;

  /// No description provided for @retry.
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinish'**
  String get retry;

  /// No description provided for @priceSum.
  ///
  /// In uz, this message translates to:
  /// **'{sum} soʻm'**
  String priceSum(String sum);

  /// No description provided for @priceFrom.
  ///
  /// In uz, this message translates to:
  /// **'{price} dan'**
  String priceFrom(String price);

  /// No description provided for @priceOnRequest.
  ///
  /// In uz, this message translates to:
  /// **'Narxini bilish'**
  String get priceOnRequest;

  /// No description provided for @priceOnRequestHint.
  ///
  /// In uz, this message translates to:
  /// **'Savatga qoʻshing va KP oling — narxni sotuvchi 1 ish kuni ichida beradi'**
  String get priceOnRequestHint;

  /// No description provided for @saleTag.
  ///
  /// In uz, this message translates to:
  /// **'Aksiya'**
  String get saleTag;

  /// No description provided for @homeSale.
  ///
  /// In uz, this message translates to:
  /// **'Aksiyadagi mahsulotlar'**
  String get homeSale;

  /// No description provided for @homeNew.
  ///
  /// In uz, this message translates to:
  /// **'Yangi qoʻshilganlar'**
  String get homeNew;

  /// No description provided for @homePopular.
  ///
  /// In uz, this message translates to:
  /// **'Ommabop'**
  String get homePopular;

  /// No description provided for @emptyCategory.
  ///
  /// In uz, this message translates to:
  /// **'Bu boʻlimda hozircha mahsulot yoʻq'**
  String get emptyCategory;

  /// No description provided for @allItems.
  ///
  /// In uz, this message translates to:
  /// **'Hammasi'**
  String get allItems;

  /// No description provided for @pricedOnly.
  ///
  /// In uz, this message translates to:
  /// **'Narxi borlar'**
  String get pricedOnly;

  /// No description provided for @sortTitle.
  ///
  /// In uz, this message translates to:
  /// **'Saralash'**
  String get sortTitle;

  /// No description provided for @sortPopular.
  ///
  /// In uz, this message translates to:
  /// **'Ommabop'**
  String get sortPopular;

  /// No description provided for @sortCheap.
  ///
  /// In uz, this message translates to:
  /// **'Arzonroq'**
  String get sortCheap;

  /// No description provided for @sortExpensive.
  ///
  /// In uz, this message translates to:
  /// **'Qimmatroq'**
  String get sortExpensive;

  /// No description provided for @sortNew.
  ///
  /// In uz, this message translates to:
  /// **'Yangilari'**
  String get sortNew;

  /// No description provided for @searchNothing.
  ///
  /// In uz, this message translates to:
  /// **'Hech narsa topilmadi'**
  String get searchNothing;

  /// No description provided for @searchNothingHint.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa soʻz yoki model nomini yozib koʻring'**
  String get searchNothingHint;

  /// No description provided for @searchFound.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta mahsulot'**
  String searchFound(int count);

  /// No description provided for @searchStartHint.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot nomi, model yoki artikul boʻyicha qidiring: masalan, «ВЦ 4-75» yoki «kanal ventilyatori»'**
  String get searchStartHint;

  /// No description provided for @searchRecent.
  ///
  /// In uz, this message translates to:
  /// **'Oxirgi qidiruvlar'**
  String get searchRecent;

  /// No description provided for @clear.
  ///
  /// In uz, this message translates to:
  /// **'Tozalash'**
  String get clear;

  /// No description provided for @modelsCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta model'**
  String modelsCount(int count);

  /// No description provided for @chooseModel.
  ///
  /// In uz, this message translates to:
  /// **'Modelni tanlang'**
  String get chooseModel;

  /// No description provided for @modelLabel.
  ///
  /// In uz, this message translates to:
  /// **'Model'**
  String get modelLabel;

  /// No description provided for @variantsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Variantlar'**
  String get variantsTitle;

  /// No description provided for @descriptionTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tavsif'**
  String get descriptionTitle;

  /// No description provided for @purposeTitle.
  ///
  /// In uz, this message translates to:
  /// **'Qoʻllanilishi'**
  String get purposeTitle;

  /// No description provided for @sellerTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sotuvchi'**
  String get sellerTitle;

  /// No description provided for @callSeller.
  ///
  /// In uz, this message translates to:
  /// **'Qoʻngʻiroq'**
  String get callSeller;

  /// No description provided for @addToCart.
  ///
  /// In uz, this message translates to:
  /// **'Savatga'**
  String get addToCart;

  /// No description provided for @chooseModelFirst.
  ///
  /// In uz, this message translates to:
  /// **'Avval modelni tanlang'**
  String get chooseModelFirst;

  /// No description provided for @addedToCart.
  ///
  /// In uz, this message translates to:
  /// **'Savatga qoʻshildi'**
  String get addedToCart;

  /// No description provided for @goToCart.
  ///
  /// In uz, this message translates to:
  /// **'Savatga oʻtish'**
  String get goToCart;

  /// No description provided for @cartEmptyTitle.
  ///
  /// In uz, this message translates to:
  /// **'Savat boʻsh'**
  String get cartEmptyTitle;

  /// No description provided for @cartEmptyBody.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulotlarni savatga soling — keyin sotib olasiz yoki KP olasiz'**
  String get cartEmptyBody;

  /// No description provided for @goToCatalog.
  ///
  /// In uz, this message translates to:
  /// **'Katalogga oʻtish'**
  String get goToCatalog;

  /// No description provided for @cartClearConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Savatni tozalaysizmi?'**
  String get cartClearConfirm;

  /// No description provided for @cartTotal.
  ///
  /// In uz, this message translates to:
  /// **'Jami'**
  String get cartTotal;

  /// No description provided for @cartUnpriced.
  ///
  /// In uz, this message translates to:
  /// **'+ {count} ta mahsulot narxini sotuvchi beradi'**
  String cartUnpriced(int count);

  /// No description provided for @checkoutOrder.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma berish'**
  String get checkoutOrder;

  /// No description provided for @checkoutQuote.
  ///
  /// In uz, this message translates to:
  /// **'KP olish'**
  String get checkoutQuote;

  /// No description provided for @checkoutSoonTitle.
  ///
  /// In uz, this message translates to:
  /// **'Rasmiylashtirish keyingi versiyada'**
  String get checkoutSoonTitle;

  /// No description provided for @checkoutSoonBody.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma berish va KP olish ilovaning keyingi versiyasida qoʻshiladi. Savatingiz shu telefonda saqlanib turadi.'**
  String get checkoutSoonBody;

  /// No description provided for @understood.
  ///
  /// In uz, this message translates to:
  /// **'Tushunarli'**
  String get understood;

  /// No description provided for @favoritesTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sevimlilar'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sevimlilar roʻyxati boʻsh'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyBody.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulotdagi ♡ belgisini bosing — u shu yerda saqlanadi'**
  String get favoritesEmptyBody;

  /// No description provided for @sizesTitle.
  ///
  /// In uz, this message translates to:
  /// **'Oʻlchamlar'**
  String get sizesTitle;

  /// No description provided for @markingTitle.
  ///
  /// In uz, this message translates to:
  /// **'Belgilanishi'**
  String get markingTitle;

  /// No description provided for @chooseVariant.
  ///
  /// In uz, this message translates to:
  /// **'Variantni tanlang'**
  String get chooseVariant;

  /// No description provided for @chooseVariantFirst.
  ///
  /// In uz, this message translates to:
  /// **'Avval variantni tanlang'**
  String get chooseVariantFirst;

  /// No description provided for @specsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Xarakteristikalar'**
  String get specsTitle;

  /// No description provided for @specsChooseModel.
  ///
  /// In uz, this message translates to:
  /// **'Modelni tanlang — uning texnik xarakteristikalari shu yerda chiqadi'**
  String get specsChooseModel;

  /// No description provided for @specAirflow.
  ///
  /// In uz, this message translates to:
  /// **'Havo sarfi'**
  String get specAirflow;

  /// No description provided for @specPressure.
  ///
  /// In uz, this message translates to:
  /// **'Bosim'**
  String get specPressure;

  /// No description provided for @checkoutOrderTitle.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmani rasmiylashtirish'**
  String get checkoutOrderTitle;

  /// No description provided for @checkoutQuoteTitle.
  ///
  /// In uz, this message translates to:
  /// **'KP soʻrovi'**
  String get checkoutQuoteTitle;

  /// No description provided for @checkoutQuoteNote.
  ///
  /// In uz, this message translates to:
  /// **'Sotuvchi narxlarni 1 ish kuni ichida yuboradi. KP tayyor boʻlganda SMS keladi va uni «Buyurtmalar» boʻlimida koʻrasiz.'**
  String get checkoutQuoteNote;

  /// No description provided for @checkoutLoginTitle.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish uchun kiring'**
  String get checkoutLoginTitle;

  /// No description provided for @checkoutLoginBody.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma va KP hisobingizga bogʻlanadi — holatini ilovada kuzatasiz'**
  String get checkoutLoginBody;

  /// No description provided for @deliveryAddress.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazish manzili'**
  String get deliveryAddress;

  /// No description provided for @deliveryAddressOptional.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazish manzili (ixtiyoriy)'**
  String get deliveryAddressOptional;

  /// No description provided for @addressLabel.
  ///
  /// In uz, this message translates to:
  /// **'Manzil'**
  String get addressLabel;

  /// No description provided for @addressRequired.
  ///
  /// In uz, this message translates to:
  /// **'Manzilni kiriting yoki xaritada belgilang'**
  String get addressRequired;

  /// No description provided for @addressDetailsLabel.
  ///
  /// In uz, this message translates to:
  /// **'Kirish, qavat, xonadon, moʻljal'**
  String get addressDetailsLabel;

  /// No description provided for @recipientTitle.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qiluvchi'**
  String get recipientTitle;

  /// No description provided for @recipientName.
  ///
  /// In uz, this message translates to:
  /// **'Ism va familiya'**
  String get recipientName;

  /// No description provided for @companyTitle.
  ///
  /// In uz, this message translates to:
  /// **'Kompaniya (ixtiyoriy)'**
  String get companyTitle;

  /// No description provided for @companyName.
  ///
  /// In uz, this message translates to:
  /// **'Kompaniya nomi'**
  String get companyName;

  /// No description provided for @companyTin.
  ///
  /// In uz, this message translates to:
  /// **'STIR'**
  String get companyTin;

  /// No description provided for @companyTinInvalid.
  ///
  /// In uz, this message translates to:
  /// **'STIR 9 ta raqamdan iborat'**
  String get companyTinInvalid;

  /// No description provided for @commentTitle.
  ///
  /// In uz, this message translates to:
  /// **'Izoh'**
  String get commentTitle;

  /// No description provided for @commentHint.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: montaj bilan, yuk koʻtaruvchi kerak'**
  String get commentHint;

  /// No description provided for @sendQuoteRequest.
  ///
  /// In uz, this message translates to:
  /// **'KP soʻrovini yuborish'**
  String get sendQuoteRequest;

  /// No description provided for @confirmOrder.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmani tasdiqlash'**
  String get confirmOrder;

  /// No description provided for @paymentNote.
  ///
  /// In uz, this message translates to:
  /// **'Toʻlov sotuvchiga: bank oʻtkazmasi, karta yoki naqd. Sotuvchi siz bilan bogʻlanib, yetkazish va toʻlovni kelishadi.'**
  String get paymentNote;

  /// No description provided for @mapPick.
  ///
  /// In uz, this message translates to:
  /// **'Xaritada belgilash'**
  String get mapPick;

  /// No description provided for @mapChange.
  ///
  /// In uz, this message translates to:
  /// **'Oʻzgartirish'**
  String get mapChange;

  /// No description provided for @mapMoving.
  ///
  /// In uz, this message translates to:
  /// **'Joyni tanlang…'**
  String get mapMoving;

  /// No description provided for @mapLoadingAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzil aniqlanmoqda…'**
  String get mapLoadingAddress;

  /// No description provided for @mapConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Shu manzil'**
  String get mapConfirm;

  /// No description provided for @locationOff.
  ///
  /// In uz, this message translates to:
  /// **'Telefonda joylashuv oʻchiq'**
  String get locationOff;

  /// No description provided for @locationDenied.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuvga ruxsat berilmadi'**
  String get locationDenied;

  /// No description provided for @locationFailed.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuvni aniqlab boʻlmadi'**
  String get locationFailed;

  /// No description provided for @doneOrderTitle.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma qabul qilindi'**
  String get doneOrderTitle;

  /// No description provided for @doneQuoteTitle.
  ///
  /// In uz, this message translates to:
  /// **'KP soʻrovi yuborildi'**
  String get doneQuoteTitle;

  /// No description provided for @doneOrderBody.
  ///
  /// In uz, this message translates to:
  /// **'Sotuvchi tez orada siz bilan bogʻlanib, yetkazish va toʻlovni kelishadi.'**
  String get doneOrderBody;

  /// No description provided for @doneQuoteBody.
  ///
  /// In uz, this message translates to:
  /// **'Sotuvchi narxlarni 1 ish kuni ichida yuboradi. KP tayyor boʻlganda SMS keladi.'**
  String get doneQuoteBody;

  /// No description provided for @myOrders.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalarim'**
  String get myOrders;

  /// No description provided for @continueShopping.
  ///
  /// In uz, this message translates to:
  /// **'Xaridni davom ettirish'**
  String get continueShopping;

  /// No description provided for @ordersLoginTitle.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalaringiz shu yerda'**
  String get ordersLoginTitle;

  /// No description provided for @ordersLoginBody.
  ///
  /// In uz, this message translates to:
  /// **'Kiring — buyurtmalar, KP lar va yetkazish holatini koʻrasiz'**
  String get ordersLoginBody;

  /// No description provided for @ordersEmptyTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hali buyurtma yoʻq'**
  String get ordersEmptyTitle;

  /// No description provided for @ordersEmptyBody.
  ///
  /// In uz, this message translates to:
  /// **'Katalogdan mahsulot tanlang — buyurtma yoki KP shu yerda paydo boʻladi'**
  String get ordersEmptyBody;

  /// No description provided for @quoteLabel.
  ///
  /// In uz, this message translates to:
  /// **'KP'**
  String get quoteLabel;

  /// No description provided for @orderLabel.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma'**
  String get orderLabel;

  /// No description provided for @priceAwaited.
  ///
  /// In uz, this message translates to:
  /// **'Narx kutilmoqda'**
  String get priceAwaited;

  /// No description provided for @statusNew.
  ///
  /// In uz, this message translates to:
  /// **'Yangi'**
  String get statusNew;

  /// No description provided for @statusQuotePending.
  ///
  /// In uz, this message translates to:
  /// **'Sotuvchi narx bermoqda'**
  String get statusQuotePending;

  /// No description provided for @statusQuoteReady.
  ///
  /// In uz, this message translates to:
  /// **'KP tayyor'**
  String get statusQuoteReady;

  /// No description provided for @statusPaid.
  ///
  /// In uz, this message translates to:
  /// **'Toʻlangan'**
  String get statusPaid;

  /// No description provided for @statusShipping.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazilmoqda'**
  String get statusShipping;

  /// No description provided for @statusDone.
  ///
  /// In uz, this message translates to:
  /// **'Yakunlangan'**
  String get statusDone;

  /// No description provided for @statusCancelled.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilingan'**
  String get statusCancelled;

  /// No description provided for @itemsCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta mahsulot'**
  String itemsCount(int count);

  /// No description provided for @moreItems.
  ///
  /// In uz, this message translates to:
  /// **'yana {count} ta'**
  String moreItems(int count);

  /// No description provided for @checkoutSplit.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulotlar {count} ta doʻkondan — har biriga alohida buyurtma yuboriladi'**
  String checkoutSplit(int count);

  /// No description provided for @doneNumbers.
  ///
  /// In uz, this message translates to:
  /// **'Raqam: {numbers}'**
  String doneNumbers(String numbers);

  /// No description provided for @checkoutPartial.
  ///
  /// In uz, this message translates to:
  /// **'{ids} yuborildi, qolganini yuborib boʻlmadi — qayta urinib koʻring'**
  String checkoutPartial(String ids);

  /// No description provided for @chooseOptions.
  ///
  /// In uz, this message translates to:
  /// **'Tanlash'**
  String get chooseOptions;

  /// No description provided for @searchInList.
  ///
  /// In uz, this message translates to:
  /// **'Roʻyxatdan qidirish'**
  String get searchInList;

  /// No description provided for @bannerMore.
  ///
  /// In uz, this message translates to:
  /// **'Batafsil'**
  String get bannerMore;

  /// No description provided for @inCartCount.
  ///
  /// In uz, this message translates to:
  /// **'Savatda · {count}'**
  String inCartCount(int count);

  /// No description provided for @pdfFailed.
  ///
  /// In uz, this message translates to:
  /// **'PDF tayyorlab boʻlmadi. Internetni tekshirib, qayta urinib koʻring'**
  String get pdfFailed;

  /// No description provided for @kpTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tijorat taklifi'**
  String get kpTitle;

  /// No description provided for @kpDate.
  ///
  /// In uz, this message translates to:
  /// **'Sana'**
  String get kpDate;

  /// No description provided for @kpValidUntil.
  ///
  /// In uz, this message translates to:
  /// **'Amal qiladi'**
  String get kpValidUntil;

  /// No description provided for @kpSeller.
  ///
  /// In uz, this message translates to:
  /// **'Sotuvchi'**
  String get kpSeller;

  /// No description provided for @kpBuyer.
  ///
  /// In uz, this message translates to:
  /// **'Xaridor'**
  String get kpBuyer;

  /// No description provided for @kpColProduct.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot'**
  String get kpColProduct;

  /// No description provided for @kpColQty.
  ///
  /// In uz, this message translates to:
  /// **'Soni'**
  String get kpColQty;

  /// No description provided for @kpColPrice.
  ///
  /// In uz, this message translates to:
  /// **'Narxi, soʻm'**
  String get kpColPrice;

  /// No description provided for @kpColSum.
  ///
  /// In uz, this message translates to:
  /// **'Summa, soʻm'**
  String get kpColSum;

  /// No description provided for @kpUnpricedCell.
  ///
  /// In uz, this message translates to:
  /// **'narxini sotuvchi beradi'**
  String get kpUnpricedCell;

  /// No description provided for @kpDeliveryTerms.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazish'**
  String get kpDeliveryTerms;

  /// No description provided for @kpPaymentTerms.
  ///
  /// In uz, this message translates to:
  /// **'Toʻlov'**
  String get kpPaymentTerms;

  /// No description provided for @kpDisclaimer.
  ///
  /// In uz, this message translates to:
  /// **'Narxlar sanadagi kurs boʻyicha. Yakuniy shartlar sotuvchi bilan kelishiladi. Ushbu hujjat ommaviy oferta emas.'**
  String get kpDisclaimer;

  /// No description provided for @kpDownloadPdf.
  ///
  /// In uz, this message translates to:
  /// **'PDF yuklab olish'**
  String get kpDownloadPdf;

  /// No description provided for @kpAccept.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qilaman — buyurtma berish'**
  String get kpAccept;

  /// No description provided for @kpAcceptConfirmTitle.
  ///
  /// In uz, this message translates to:
  /// **'KP ni qabul qilasizmi?'**
  String get kpAcceptConfirmTitle;

  /// No description provided for @kpAccepted.
  ///
  /// In uz, this message translates to:
  /// **'KP qabul qilindi — buyurtma rasmiylashtirildi'**
  String get kpAccepted;

  /// No description provided for @kpReject.
  ///
  /// In uz, this message translates to:
  /// **'Rad etish'**
  String get kpReject;

  /// No description provided for @kpRejectTitle.
  ///
  /// In uz, this message translates to:
  /// **'KP ni rad etish'**
  String get kpRejectTitle;

  /// No description provided for @kpRejectHint.
  ///
  /// In uz, this message translates to:
  /// **'Sababi (ixtiyoriy): masalan, qimmat'**
  String get kpRejectHint;

  /// No description provided for @kpRejected.
  ///
  /// In uz, this message translates to:
  /// **'KP rad etildi'**
  String get kpRejected;

  /// No description provided for @kpRequestAgain.
  ///
  /// In uz, this message translates to:
  /// **'Yangisini olish'**
  String get kpRequestAgain;

  /// No description provided for @kpRequestedAgain.
  ///
  /// In uz, this message translates to:
  /// **'Soʻrov sotuvchiga yuborildi'**
  String get kpRequestedAgain;

  /// No description provided for @kpPreparing.
  ///
  /// In uz, this message translates to:
  /// **'Sotuvchi KP tayyorlayapti — odatda 1 ish kuni. Tayyor boʻlganda SMS keladi.'**
  String get kpPreparing;

  /// No description provided for @kpExpired.
  ///
  /// In uz, this message translates to:
  /// **'KP muddati oʻtgan — yangisini soʻrang'**
  String get kpExpired;

  /// No description provided for @statusQuoteExpired.
  ///
  /// In uz, this message translates to:
  /// **'KP eskirgan'**
  String get statusQuoteExpired;

  /// No description provided for @kpAcceptConfirmBody.
  ///
  /// In uz, this message translates to:
  /// **'Jami {total}. Sotuvchi siz bilan bogʻlanib, yetkazish va toʻlovni kelishadi.'**
  String kpAcceptConfirmBody(String total);

  /// No description provided for @kpPartial.
  ///
  /// In uz, this message translates to:
  /// **'Sotuvchi {count} ta mahsulotga narx tayyorlayapti — KP toʻliq boʻlganda SMS keladi'**
  String kpPartial(int count);

  /// No description provided for @kpIssueNow.
  ///
  /// In uz, this message translates to:
  /// **'KP hujjatini hozir olish'**
  String get kpIssueNow;

  /// No description provided for @kpIssued.
  ///
  /// In uz, this message translates to:
  /// **'KP tayyor — narxli mahsulotlar hujjatda'**
  String get kpIssued;

  /// No description provided for @kpTo.
  ///
  /// In uz, this message translates to:
  /// **'Kimga:'**
  String get kpTo;

  /// No description provided for @kpToHead.
  ///
  /// In uz, this message translates to:
  /// **'Rahbariga:'**
  String get kpToHead;

  /// No description provided for @kpColName.
  ///
  /// In uz, this message translates to:
  /// **'Nomi'**
  String get kpColName;

  /// No description provided for @kpColUnit.
  ///
  /// In uz, this message translates to:
  /// **'Oʻlch. birl.'**
  String get kpColUnit;

  /// No description provided for @kpColUnitPrice.
  ///
  /// In uz, this message translates to:
  /// **'Dona narxi'**
  String get kpColUnitPrice;

  /// No description provided for @kpColAmount.
  ///
  /// In uz, this message translates to:
  /// **'Summa'**
  String get kpColAmount;

  /// No description provided for @kpColVat.
  ///
  /// In uz, this message translates to:
  /// **'QQS 12%'**
  String get kpColVat;

  /// No description provided for @kpColTotalVat.
  ///
  /// In uz, this message translates to:
  /// **'QQS bilan summa'**
  String get kpColTotalVat;

  /// No description provided for @kpUnit.
  ///
  /// In uz, this message translates to:
  /// **'dona'**
  String get kpUnit;

  /// No description provided for @kpTotalRow.
  ///
  /// In uz, this message translates to:
  /// **'Jami:'**
  String get kpTotalRow;

  /// No description provided for @kpRegards.
  ///
  /// In uz, this message translates to:
  /// **'Hurmat bilan,'**
  String get kpRegards;

  /// No description provided for @kpVatNote.
  ///
  /// In uz, this message translates to:
  /// **'Narxlar QQS 12% bilan, soʻmda.'**
  String get kpVatNote;

  /// No description provided for @kpDated.
  ///
  /// In uz, this message translates to:
  /// **'{date} y.'**
  String kpDated(String date);

  /// No description provided for @kpIntro.
  ///
  /// In uz, this message translates to:
  /// **'{seller} buyurtmangiz boʻyicha quyidagi uskunalarni yetkazib bera oladi:'**
  String kpIntro(String seller);

  /// No description provided for @kpValidRange.
  ///
  /// In uz, this message translates to:
  /// **'*Mahsulot narxlari {from} dan {to} gacha amal qiladi'**
  String kpValidRange(String from, String to);

  /// No description provided for @kpDirectorOf.
  ///
  /// In uz, this message translates to:
  /// **'{company} direktori'**
  String kpDirectorOf(String company);

  /// No description provided for @kpHeadOf.
  ///
  /// In uz, this message translates to:
  /// **'{company} rahbari'**
  String kpHeadOf(String company);

  /// No description provided for @specsEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Xarakteristikasi yoʻq'**
  String get specsEmpty;

  /// No description provided for @variantsCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta variant'**
  String variantsCount(int count);

  /// No description provided for @orderItemsSummary.
  ///
  /// In uz, this message translates to:
  /// **'{name} va yana {count} ta'**
  String orderItemsSummary(String name, int count);

  /// No description provided for @piecesCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} dona'**
  String piecesCount(int count);

  /// No description provided for @priceSheetBody.
  ///
  /// In uz, this message translates to:
  /// **'Sotuvchi narxni KP orqali 1 ish kuni ichida beradi. Tezroq kerak boʻlsa — qoʻngʻiroq qiling yoki Telegramda yozing.'**
  String get priceSheetBody;

  /// No description provided for @priceSheetQuote.
  ///
  /// In uz, this message translates to:
  /// **'KP olish — narxni 1 ish kunida beramiz'**
  String get priceSheetQuote;

  /// No description provided for @priceSheetTelegram.
  ///
  /// In uz, this message translates to:
  /// **'Telegramda yozish'**
  String get priceSheetTelegram;

  /// No description provided for @priceSheetCall.
  ///
  /// In uz, this message translates to:
  /// **'Qoʻngʻiroq · {store}'**
  String priceSheetCall(String store);
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'ru':
      return SRu();
    case 'uz':
      return SUz();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
