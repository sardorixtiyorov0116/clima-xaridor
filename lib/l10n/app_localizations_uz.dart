// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class SUz extends S {
  SUz([String locale = 'uz']) : super(locale);

  @override
  String get appName => 'Climavent';

  @override
  String get tagline => 'Ventilyatsiya va konditsioner uskunalari';

  @override
  String get langTitle => 'Tilni tanlang';

  @override
  String get langSubtitle =>
      'Keyinroq profil sozlamalarida oʻzgartirish mumkin';

  @override
  String get continueAction => 'Davom etish';

  @override
  String get onb1Title => 'Ishlab chiqaruvchidan toʻgʻridan-toʻgʻri';

  @override
  String get onb1Body =>
      'Ventilyatorlar, konditsionerlar, havo kanallari — Oʻzbekistondagi zavod va doʻkonlardan.';

  @override
  String get onb2Title => 'Tijorat taklifi bir zumda';

  @override
  String get onb2Body =>
      'Savatga soling va sotib olishdan oldin KP ni PDF qilib oling — rahbariyatga tasdiqlatish uchun.';

  @override
  String get onb3Title => 'Yetkazishni jonli kuzating';

  @override
  String get onb3Body =>
      'Kuryer qayerda va qachon yetib kelishini xaritada koʻrasiz.';

  @override
  String get onbNext => 'Keyingisi';

  @override
  String get onbStart => 'Boshlash';

  @override
  String get onbSkip => 'Oʻtkazib yuborish';

  @override
  String get phoneTitle => 'Telefon raqamingiz';

  @override
  String get phoneSubtitle =>
      'Kirish yoki roʻyxatdan oʻtish uchun SMS orqali kod yuboramiz';

  @override
  String get phoneLabel => 'Telefon raqami';

  @override
  String get phoneInvalid => 'Raqamni toʻliq kiriting: 9 ta raqam';

  @override
  String get getCode => 'Kodni olish';

  @override
  String get later => 'Keyinroq';

  @override
  String get phoneFooter =>
      'Davom etib, siz SMS olishga rozilik bildirasiz. Standart operator tarifi.';

  @override
  String get consentTitle => 'Siz bizda yangisiz';

  @override
  String get consentBody =>
      'Hisob yaratish uchun shartlar bilan tanishib chiqing va rozilik bering.';

  @override
  String get consentPrefix => 'Men ';

  @override
  String get consentTerms => 'Foydalanish shartlari';

  @override
  String get consentAnd => ' va ';

  @override
  String get consentPrivacy => 'Maxfiylik siyosati';

  @override
  String get consentSuffix => ' bilan tanishdim va roziman';

  @override
  String get consentAccept => 'Roziman, kodni yuborish';

  @override
  String get otpTitle => 'Kodni kiriting';

  @override
  String otpSubtitle(String phone) {
    return '$phone raqamiga 5 xonali kod yubordik';
  }

  @override
  String get otpChangeNumber => 'Raqamni oʻzgartirish';

  @override
  String otpResendIn(String time) {
    return 'Kodni qayta yuborish: $time';
  }

  @override
  String get otpResend => 'Kodni qayta yuborish';

  @override
  String get otpResent => 'Yangi kod yuborildi';

  @override
  String get otpWrong => 'Kod notoʻgʻri. Qaytadan urinib koʻring';

  @override
  String get otpExpired => 'Kodning muddati tugadi. Yangisini soʻrang';

  @override
  String get otpVerifying => 'Tekshirilmoqda…';

  @override
  String get profileSetupTitle => 'Tanishib olaylik';

  @override
  String get profileSetupSubtitle =>
      'Ismingiz buyurtma va tijorat takliflarida koʻrsatiladi';

  @override
  String get firstName => 'Ism';

  @override
  String get lastName => 'Familiya';

  @override
  String get firstNameRequired => 'Ismingizni kiriting';

  @override
  String get save => 'Saqlash';

  @override
  String welcome(String name) {
    return 'Xush kelibsiz, $name!';
  }

  @override
  String get welcomeNoName => 'Xush kelibsiz!';

  @override
  String get tabHome => 'Bosh sahifa';

  @override
  String get tabCatalog => 'Katalog';

  @override
  String get tabCart => 'Savat';

  @override
  String get tabOrders => 'Buyurtmalar';

  @override
  String get tabProfile => 'Profil';

  @override
  String get searchHint => 'Mahsulot yoki model qidirish';

  @override
  String get soonTitle => 'Tez orada';

  @override
  String get soonCatalog =>
      'Katalog shu yerda boʻladi: mahsulotlar, modellar va filtrlar.';

  @override
  String get soonCart =>
      'Savatdan sotib olish yoki KP olish — ikkalasi ham bir tugmada.';

  @override
  String get soonOrders =>
      'Buyurtmalar, KP lar va yetkazishni kuzatish shu yerda.';

  @override
  String get homeHeroTitle => 'Ilova ishga tushmoqda';

  @override
  String get homeHeroBody =>
      'Birinchi bosqich — kirish va hisob. Katalog, savat va kuzatish navbatda.';

  @override
  String get guestTitle => 'Hisobingizga kiring';

  @override
  String get guestBody =>
      'Buyurtmalar, tijorat takliflari va yetkazish holati bir joyda';

  @override
  String get signIn => 'Kirish';

  @override
  String get settingsLanguage => 'Til';

  @override
  String get settingsTheme => 'Mavzu';

  @override
  String get themeSystem => 'Tizim boʻyicha';

  @override
  String get themeLight => 'Yorugʻ';

  @override
  String get themeDark => 'Qorongʻi';

  @override
  String get settingsTerms => 'Foydalanish shartlari';

  @override
  String get settingsPrivacy => 'Maxfiylik siyosati';

  @override
  String get settingsSupport => 'Qoʻllab-quvvatlash';

  @override
  String get signOut => 'Chiqish';

  @override
  String get signOutConfirm => 'Hisobdan chiqasizmi?';

  @override
  String get cancel => 'Bekor qilish';

  @override
  String version(String v) {
    return 'Versiya $v';
  }

  @override
  String get errNetwork => 'Internet bilan aloqa yoʻq. Ulanishni tekshiring';

  @override
  String get errServer => 'Serverda xatolik. Birozdan keyin urinib koʻring';

  @override
  String get errTooMany =>
      'Urinishlar juda koʻp. Birozdan keyin qayta urinib koʻring';

  @override
  String get errUnknown => 'Kutilmagan xatolik yuz berdi';

  @override
  String get retry => 'Qayta urinish';

  @override
  String priceSum(String sum) {
    return '$sum soʻm';
  }

  @override
  String priceFrom(String price) {
    return '$price dan';
  }

  @override
  String get priceOnRequest => 'Narxini bilish';

  @override
  String get priceOnRequestHint =>
      'Savatga qoʻshing va KP oling — narxni sotuvchi 1 ish kuni ichida beradi';

  @override
  String get saleTag => 'Aksiya';

  @override
  String get homeSale => 'Aksiyadagi mahsulotlar';

  @override
  String get homeNew => 'Yangi qoʻshilganlar';

  @override
  String get homePopular => 'Ommabop';

  @override
  String get emptyCategory => 'Bu boʻlimda hozircha mahsulot yoʻq';

  @override
  String get allItems => 'Hammasi';

  @override
  String get pricedOnly => 'Narxi borlar';

  @override
  String get sortTitle => 'Saralash';

  @override
  String get sortPopular => 'Ommabop';

  @override
  String get sortCheap => 'Arzonroq';

  @override
  String get sortExpensive => 'Qimmatroq';

  @override
  String get sortNew => 'Yangilari';

  @override
  String get searchNothing => 'Hech narsa topilmadi';

  @override
  String get searchNothingHint => 'Boshqa soʻz yoki model nomini yozib koʻring';

  @override
  String searchFound(int count) {
    return '$count ta mahsulot';
  }

  @override
  String get searchStartHint =>
      'Mahsulot nomi, model yoki artikul boʻyicha qidiring: masalan, «ВЦ 4-75» yoki «kanal ventilyatori»';

  @override
  String get searchRecent => 'Oxirgi qidiruvlar';

  @override
  String get clear => 'Tozalash';

  @override
  String modelsCount(int count) {
    return '$count ta model';
  }

  @override
  String get chooseModel => 'Modelni tanlang';

  @override
  String get modelLabel => 'Model';

  @override
  String get variantsTitle => 'Variantlar';

  @override
  String get descriptionTitle => 'Tavsif';

  @override
  String get purposeTitle => 'Qoʻllanilishi';

  @override
  String get sellerTitle => 'Sotuvchi';

  @override
  String get addToCart => 'Savatga';

  @override
  String get chooseModelFirst => 'Avval modelni tanlang';

  @override
  String get addedToCart => 'Savatga qoʻshildi';

  @override
  String get goToCart => 'Savatga oʻtish';

  @override
  String get cartEmptyTitle => 'Savat boʻsh';

  @override
  String get cartEmptyBody =>
      'Mahsulotlarni savatga soling — keyin sotib olasiz yoki KP olasiz';

  @override
  String get goToCatalog => 'Katalogga oʻtish';

  @override
  String get cartClearConfirm => 'Savatni tozalaysizmi?';

  @override
  String get cartTotal => 'Jami';

  @override
  String cartUnpriced(int count) {
    return '+ $count ta mahsulot narxini sotuvchi beradi';
  }

  @override
  String get checkoutOrder => 'Buyurtma berish';

  @override
  String get checkoutQuote => 'KP olish';

  @override
  String get checkoutSoonTitle => 'Rasmiylashtirish keyingi versiyada';

  @override
  String get checkoutSoonBody =>
      'Buyurtma berish va KP olish ilovaning keyingi versiyasida qoʻshiladi. Savatingiz shu telefonda saqlanib turadi.';

  @override
  String get understood => 'Tushunarli';

  @override
  String get favoritesTitle => 'Sevimlilar';

  @override
  String get favoritesEmptyTitle => 'Sevimlilar roʻyxati boʻsh';

  @override
  String get favoritesEmptyBody =>
      'Mahsulotdagi ♡ belgisini bosing — u shu yerda saqlanadi';

  @override
  String get sizesTitle => 'Oʻlchamlar';

  @override
  String get markingTitle => 'Belgilanishi';

  @override
  String get chooseVariant => 'Variantni tanlang';

  @override
  String get chooseVariantFirst => 'Avval variantni tanlang';

  @override
  String get specsTitle => 'Xarakteristikalar';

  @override
  String get specsChooseModel =>
      'Modelni tanlang — uning texnik xarakteristikalari shu yerda chiqadi';

  @override
  String get specAirflow => 'Havo sarfi';

  @override
  String get specPressure => 'Bosim';

  @override
  String get checkoutOrderTitle => 'Buyurtmani rasmiylashtirish';

  @override
  String get checkoutQuoteTitle => 'KP soʻrovi';

  @override
  String get checkoutQuoteNote =>
      'Narxlarni 1 ish kuni ichida tayyorlaymiz. KP tayyor boʻlganda xabar beramiz va uni «Buyurtmalar» boʻlimida koʻrasiz.';

  @override
  String get checkoutLoginTitle => 'Davom etish uchun kiring';

  @override
  String get checkoutLoginBody =>
      'Buyurtma va KP hisobingizga bogʻlanadi — holatini ilovada kuzatasiz';

  @override
  String get deliveryAddress => 'Yetkazish manzili';

  @override
  String get addressLabel => 'Manzil';

  @override
  String get addressRequired => 'Manzilni kiriting yoki xaritada belgilang';

  @override
  String get addressDetailsLabel => 'Kirish, qavat, xonadon, moʻljal';

  @override
  String get recipientTitle => 'Qabul qiluvchi';

  @override
  String get recipientName => 'Ism va familiya';

  @override
  String get companyTitle => 'Kompaniya (ixtiyoriy)';

  @override
  String get companyName => 'Kompaniya nomi';

  @override
  String get companyTin => 'STIR';

  @override
  String get companyTinInvalid => 'STIR 9 ta raqamdan iborat';

  @override
  String get commentTitle => 'Izoh';

  @override
  String get commentHint => 'Masalan: montaj bilan, yuk koʻtaruvchi kerak';

  @override
  String get sendQuoteRequest => 'KP soʻrovini yuborish';

  @override
  String get confirmOrder => 'Buyurtmani tasdiqlash';

  @override
  String get paymentNote =>
      'Toʻlov sotuvchiga: bank oʻtkazmasi, karta yoki naqd. Sotuvchi siz bilan bogʻlanib, yetkazish va toʻlovni kelishadi.';

  @override
  String get mapPick => 'Xaritada belgilash';

  @override
  String get mapChange => 'Oʻzgartirish';

  @override
  String get mapMoving => 'Joyni tanlang…';

  @override
  String get mapLoadingAddress => 'Manzil aniqlanmoqda…';

  @override
  String get mapConfirm => 'Shu manzil';

  @override
  String get locationOff => 'Telefonda joylashuv oʻchiq';

  @override
  String get locationDenied => 'Joylashuvga ruxsat berilmadi';

  @override
  String get locationFailed => 'Joylashuvni aniqlab boʻlmadi';

  @override
  String get doneOrderTitle => 'Buyurtma qabul qilindi';

  @override
  String get doneQuoteTitle => 'KP soʻrovi yuborildi';

  @override
  String get doneOrderBody =>
      'Sotuvchi tez orada siz bilan bogʻlanib, yetkazish va toʻlovni kelishadi.';

  @override
  String get doneQuoteBody =>
      'Sotuvchi narxlarni 1 ish kuni ichida yuboradi. KP tayyor boʻlganda SMS keladi.';

  @override
  String get myOrders => 'Buyurtmalarim';

  @override
  String get continueShopping => 'Xaridni davom ettirish';

  @override
  String get ordersLoginTitle => 'Buyurtmalaringiz shu yerda';

  @override
  String get ordersLoginBody =>
      'Kiring — buyurtmalar, KP lar va yetkazish holatini koʻrasiz';

  @override
  String get ordersEmptyTitle => 'Hali buyurtma yoʻq';

  @override
  String get ordersEmptyBody =>
      'Katalogdan mahsulot tanlang — buyurtma yoki KP shu yerda paydo boʻladi';

  @override
  String get quoteLabel => 'KP';

  @override
  String get orderLabel => 'Buyurtma';

  @override
  String get priceAwaited => 'Narx kutilmoqda';

  @override
  String get statusNew => 'Yangi';

  @override
  String get statusQuotePending => 'Sotuvchi narx bermoqda';

  @override
  String get statusQuoteReady => 'KP tayyor';

  @override
  String get statusPaid => 'Toʻlangan';

  @override
  String get statusShipping => 'Yetkazilmoqda';

  @override
  String get statusDone => 'Yakunlangan';

  @override
  String get statusCancelled => 'Bekor qilingan';

  @override
  String itemsCount(int count) {
    return '$count ta mahsulot';
  }

  @override
  String moreItems(int count) {
    return 'yana $count ta';
  }

  @override
  String checkoutSplit(int count) {
    return 'Mahsulotlar $count ta doʻkondan — har biriga alohida buyurtma yuboriladi';
  }

  @override
  String doneNumbers(String numbers) {
    return 'Raqam: $numbers';
  }

  @override
  String checkoutPartial(String ids) {
    return '$ids yuborildi, qolganini yuborib boʻlmadi — qayta urinib koʻring';
  }

  @override
  String get chooseOptions => 'Tanlash';

  @override
  String get searchInList => 'Roʻyxatdan qidirish';

  @override
  String get bannerMore => 'Batafsil';

  @override
  String inCartCount(int count) {
    return 'Savatda · $count';
  }

  @override
  String get pdfFailed =>
      'PDF tayyorlab boʻlmadi. Internetni tekshirib, qayta urinib koʻring';

  @override
  String get kpTitle => 'Tijorat taklifi';

  @override
  String get kpDate => 'Sana';

  @override
  String get kpValidUntil => 'Amal qiladi';

  @override
  String get kpBuyer => 'Xaridor';

  @override
  String get kpColProduct => 'Mahsulot';

  @override
  String get kpColQty => 'Soni';

  @override
  String get kpColPrice => 'Narxi, soʻm';

  @override
  String get kpColSum => 'Summa, soʻm';

  @override
  String get kpUnpricedCell => 'narxini sotuvchi beradi';

  @override
  String get kpDeliveryTerms => 'Yetkazish';

  @override
  String get kpPaymentTerms => 'Toʻlov';

  @override
  String get kpDisclaimer =>
      'Narxlar sanadagi kurs boʻyicha. Yakuniy shartlar sotuvchi bilan kelishiladi. Ushbu hujjat ommaviy oferta emas.';

  @override
  String get kpDownloadPdf => 'PDF yuklab olish';

  @override
  String get kpAccept => 'Qabul qilaman — buyurtma berish';

  @override
  String get kpAcceptConfirmTitle => 'KP ni qabul qilasizmi?';

  @override
  String get kpAccepted => 'KP qabul qilindi — buyurtma rasmiylashtirildi';

  @override
  String get kpReject => 'Rad etish';

  @override
  String get kpRejectTitle => 'KP ni rad etish';

  @override
  String get kpRejectHint => 'Sababi (ixtiyoriy): masalan, qimmat';

  @override
  String get kpRejected => 'KP rad etildi';

  @override
  String get kpRequestAgain => 'Yangisini olish';

  @override
  String get kpRequestedAgain => 'Soʻrov sotuvchiga yuborildi';

  @override
  String get kpPreparing =>
      'KP tayyorlanmoqda — odatda 1 ish kuni. Tayyor boʻlganda xabar beramiz.';

  @override
  String kpWaitingCount(int count) {
    return '$count ta mahsulotga narx tayyorlanmoqda — tayyor boʻlganda xabar beramiz';
  }

  @override
  String get kpExpired => 'KP muddati oʻtgan — yangisini soʻrang';

  @override
  String get statusQuoteExpired => 'KP eskirgan';

  @override
  String kpAcceptConfirmBody(String total) {
    return 'Jami $total. Sotuvchi siz bilan bogʻlanib, yetkazish va toʻlovni kelishadi.';
  }

  @override
  String get kpTo => 'Kimga:';

  @override
  String get kpToHead => 'Rahbariga:';

  @override
  String get kpColName => 'Nomi';

  @override
  String get kpColUnit => 'Oʻlch. birl.';

  @override
  String get kpColUnitPrice => 'Dona narxi';

  @override
  String get kpColAmount => 'Summa';

  @override
  String get kpColVat => 'QQS 12%';

  @override
  String get kpColTotalVat => 'QQS bilan summa';

  @override
  String get kpUnit => 'dona';

  @override
  String get kpTotalRow => 'Jami:';

  @override
  String get kpRegards => 'Hurmat bilan,';

  @override
  String get kpVatNote => 'Narxlar QQS 12% bilan, soʻmda.';

  @override
  String kpDated(String date) {
    return '$date y.';
  }

  @override
  String kpIntro(String seller) {
    return '$seller buyurtmangiz boʻyicha quyidagi uskunalarni yetkazib bera oladi:';
  }

  @override
  String kpValidRange(String from, String to) {
    return '*Mahsulot narxlari $from dan $to gacha amal qiladi';
  }

  @override
  String kpDirectorOf(String company) {
    return '$company direktori';
  }

  @override
  String kpHeadOf(String company) {
    return '$company rahbari';
  }

  @override
  String get specsEmpty => 'Xarakteristikasi yoʻq';

  @override
  String variantsCount(int count) {
    return '$count ta variant';
  }

  @override
  String orderItemsSummary(String name, int count) {
    return '$name va yana $count ta';
  }

  @override
  String piecesCount(int count) {
    return '$count dona';
  }

  @override
  String get priceSheetBody =>
      'Sotuvchi narxni KP orqali 1 ish kuni ichida beradi. Tezroq kerak boʻlsa — sotuvchiga shu yerning oʻzida yozing.';

  @override
  String get priceSheetQuote => 'KP olish — narxni 1 ish kunida beramiz';

  @override
  String get pushTokenCopied => 'Push tokeni nusxalandi';

  @override
  String get chatWriteToStore => 'Doʻkonga yozish';

  @override
  String get chatsTitle => 'Xabarlar';

  @override
  String get chatsEmptyTitle => 'Hozircha xabar yoʻq';

  @override
  String get chatsEmptyBody =>
      'Mahsulot sahifasida «Doʻkonga yozish» ni bosing — sotuvchi javobi shu yerda chiqadi';

  @override
  String get chatsLoginBody => 'Doʻkonlar bilan yozishish uchun kiring';

  @override
  String get chatInputHint => 'Xabar yozing…';

  @override
  String get chatTyping => 'yozmoqda…';

  @override
  String get chatConnecting => 'ulanmoqda…';

  @override
  String get chatAboutProduct => 'Shu mahsulot haqida';

  @override
  String get chatEmptyTitle => 'Savolingizni yozing';

  @override
  String get chatEmptyBody => 'Sotuvchi javob berganda bildirishnoma keladi';

  @override
  String get chatQuickPrice => 'Narxi qancha boʻladi?';

  @override
  String get chatQuickStock => 'Omborda bormi?';

  @override
  String get chatQuickDelivery => 'Yetkazib berish qancha vaqt oladi?';

  @override
  String get chatFailed => 'Yuborilmadi — qayta yuborish uchun bosing';

  @override
  String get chatUnavailable => 'Chat tez orada ishga tushadi';

  @override
  String get chatYou => 'Siz: ';

  @override
  String get chatToday => 'Bugun';

  @override
  String get chatYesterday => 'Kecha';

  @override
  String get chatProductMsg => 'Mahsulot haqida savol';

  @override
  String get statusPacking => 'Yigʻilmoqda';

  @override
  String get statusReady => 'Yigʻildi';

  @override
  String get statusInProgress => 'Usta ishlayapti';

  @override
  String get trackTitle => 'Buyurtma holati';

  @override
  String get trackCreated => 'Qabul qilindi';

  @override
  String get trackPacking => 'Yigʻilmoqda';

  @override
  String get trackReady => 'Yigʻildi';

  @override
  String get trackShipping => 'Yoʻlda';

  @override
  String get trackInProgress => 'Usta ishlayapti';

  @override
  String get trackDone => 'Yakunlandi';

  @override
  String get trackCancelled => 'Bekor qilindi';

  @override
  String get trackCourier => 'Kuryer';

  @override
  String get trackCourierAssigned =>
      'Kuryer tayinlandi — tez orada yoʻlga chiqadi';

  @override
  String trackEta(int min) {
    return '~$min daqiqa';
  }

  @override
  String get trackStale =>
      'Kuryer joylashuvi bir necha daqiqadan beri yangilanmagan';

  @override
  String trackCash(String sum) {
    return 'Kuryerga $sum tayyorlab qoʻying';
  }

  @override
  String get trackDelivered => 'Yetkazildi';

  @override
  String get trackCall => 'Qoʻngʻiroq';

  @override
  String get jobTitle => 'Usta xizmati';

  @override
  String get jobWarrantyTitle => 'Kafolat boʻyicha tashrif';

  @override
  String get jobPending => 'Usta tayinlanmoqda';

  @override
  String get jobAssigned => 'Usta tayinlandi';

  @override
  String get jobAccepted => 'Usta tasdiqladi';

  @override
  String get jobOnTheWay => 'Usta yoʻlda';

  @override
  String get jobArrived => 'Usta yetib keldi';

  @override
  String get jobInProgress => 'Ish bajarilmoqda';

  @override
  String get jobCompleted => 'Bajarildi';

  @override
  String get jobFailed => 'Bajarilmadi';

  @override
  String get jobCancelled => 'Bekor qilindi';

  @override
  String get jobTime => 'Vaqt';

  @override
  String get jobTimeProposed => 'Usta tasdiqlashini kuting';

  @override
  String get jobTimeConfirmed => 'Tasdiqlangan';

  @override
  String get jobRescheduled => 'Usta boshqa vaqt taklif qildi';

  @override
  String get jobTimeAccept => 'Qabul qilaman';

  @override
  String get jobTimeReject => 'Boshqa vaqt kerak';

  @override
  String get jobTimeRejected => 'Usta siz bilan bogʻlanadi';

  @override
  String get jobCode => 'Isbot kodi';

  @override
  String get jobCodeHint => 'Ish tugagach, ustaga shu kodni ayting';

  @override
  String get jobPriceTitle => 'Usta yangi narx taklif qildi';

  @override
  String jobPriceWas(String sum) {
    return 'Buyurtmada: $sum';
  }

  @override
  String jobPriceRejectNote(String sum) {
    return 'Rad etsangiz, faqat chiqish haqi olinadi: $sum';
  }

  @override
  String get jobPriceAccept => 'Roziman';

  @override
  String get jobPriceReject => 'Rozi emasman';

  @override
  String get jobPriceAccepted => 'Narx tasdiqlandi';

  @override
  String get jobPriceRejected => 'Narx rad etildi';

  @override
  String get jobCancel => 'Xizmatni bekor qilish';

  @override
  String get jobCancelConfirm => 'Xizmat bekor qilinsinmi?';

  @override
  String get jobCancelDone => 'Xizmat bekor qilindi';

  @override
  String jobWarrantyUntil(String date) {
    return 'Kafolat $date gacha';
  }

  @override
  String get jobWarrantyClaim => 'Kafolat boʻyicha murojaat';

  @override
  String get jobWarrantyHint => 'Nima boʻldi? Qisqacha yozing';

  @override
  String get jobWarrantySent => 'Murojaat yuborildi — usta bogʻlanadi';

  @override
  String get jobRate => 'Ishni baholang';

  @override
  String get jobRateHint => 'Izoh (ixtiyoriy)';

  @override
  String get jobRateSend => 'Yuborish';

  @override
  String get jobRated => 'Rahmat! Bahoyingiz qabul qilindi';

  @override
  String get jobYourRating => 'Sizning bahoyingiz';

  @override
  String get jobPhotosAfter => 'Bajarilgan ish';

  @override
  String get servicesTitle => 'Xizmatlar';

  @override
  String get servicesHome => 'Oʻrnatish va servis';

  @override
  String get servicesAll => 'Hammasi';

  @override
  String get servicesEmpty => 'Bu hududda hozircha xizmat yoʻq';

  @override
  String get servicesEmptyBody =>
      'Boshqa tuman yoki xizmat turini tanlab koʻring';

  @override
  String get serviceArea => 'Hudud';

  @override
  String get serviceAreaPick => 'Hududni tanlang';

  @override
  String get serviceAreaWhole => 'Butun hudud';

  @override
  String serviceFrom(String sum) {
    return '$sum dan';
  }

  @override
  String get serviceByQuote => 'Narxi kelishiladi';

  @override
  String serviceWarranty(int months) {
    return 'Kafolat $months oy';
  }

  @override
  String serviceDuration(int min) {
    return '~$min daqiqa';
  }

  @override
  String serviceVisitFee(String sum) {
    return 'Chiqish haqi $sum';
  }

  @override
  String serviceJobsDone(int count) {
    return '$count ta ish bajarilgan';
  }

  @override
  String get serviceFromNote =>
      'Yakuniy narxni usta joyida aytadi — siz ilovada tasdiqlaysiz';

  @override
  String get serviceQuoteNote => 'Narxni hamkor alohida hisoblab yuboradi';

  @override
  String get serviceChooseVariant => 'Variantni tanlang';

  @override
  String get serviceOrder => 'Buyurtma berish';

  @override
  String get serviceAskPrice => 'Narx soʻrash';

  @override
  String get serviceAbout => 'Xizmat haqida';

  @override
  String get serviceCheckoutTitle => 'Xizmatga buyurtma';

  @override
  String get serviceWhere => 'Qayerga';

  @override
  String get serviceWhen => 'Qachon qulay';

  @override
  String get serviceWhenNote =>
      'Usta vaqtni tasdiqlaydi yoki boshqasini taklif qiladi';

  @override
  String get serviceDistrictRequired => 'Tumanni tanlang';

  @override
  String get serviceBooked => 'Buyurtma qabul qilindi';

  @override
  String get serviceNotInArea => 'Bu hamkor tanlangan hududda ishlamaydi';

  @override
  String get serviceToday => 'Bugun';

  @override
  String get serviceTomorrow => 'Ertaga';

  @override
  String get installTitle => 'Oʻrnatib berish';

  @override
  String get installNote => 'Doʻkon ustasi tovar yetib kelgach oʻrnatadi';

  @override
  String installFor(String name) {
    return '$name uchun';
  }

  @override
  String get installVisit => 'Oʻrnatish vaqti';

  @override
  String get serviceQty => 'Miqdori';

  @override
  String get serviceTimeWindow => 'Vaqt oraligʻi';

  @override
  String get serviceSummary => 'Buyurtma';

  @override
  String get serviceTimeRequired => 'Qulay vaqtni tanlang';
}
