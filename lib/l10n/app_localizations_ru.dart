// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class SRu extends S {
  SRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Climavent';

  @override
  String get tagline => 'Оборудование для вентиляции и кондиционирования';

  @override
  String get langTitle => 'Выберите язык';

  @override
  String get langSubtitle => 'Изменить можно позже в настройках профиля';

  @override
  String get continueAction => 'Продолжить';

  @override
  String get onb1Title => 'Напрямую от производителя';

  @override
  String get onb1Body =>
      'Вентиляторы, кондиционеры, воздуховоды — от заводов и магазинов Узбекистана.';

  @override
  String get onb2Title => 'Коммерческое предложение за секунду';

  @override
  String get onb2Body =>
      'Добавьте в корзину и получите КП в PDF ещё до покупки — для согласования с руководством.';

  @override
  String get onb3Title => 'Следите за доставкой в реальном времени';

  @override
  String get onb3Body => 'Где курьер и когда он приедет — видно на карте.';

  @override
  String get onbNext => 'Далее';

  @override
  String get onbStart => 'Начать';

  @override
  String get onbSkip => 'Пропустить';

  @override
  String get phoneTitle => 'Ваш номер телефона';

  @override
  String get phoneSubtitle => 'Отправим код по SMS для входа или регистрации';

  @override
  String get phoneLabel => 'Номер телефона';

  @override
  String get phoneInvalid => 'Введите номер полностью: 9 цифр';

  @override
  String get getCode => 'Получить код';

  @override
  String get later => 'Позже';

  @override
  String get phoneFooter =>
      'Продолжая, вы соглашаетесь получить SMS. Тариф оператора стандартный.';

  @override
  String get consentTitle => 'Вы у нас впервые';

  @override
  String get consentBody =>
      'Чтобы создать аккаунт, ознакомьтесь с условиями и дайте согласие.';

  @override
  String get consentPrefix => 'Я ознакомился(-ась) и согласен(-на) с ';

  @override
  String get consentTerms => 'Пользовательским соглашением';

  @override
  String get consentAnd => ' и ';

  @override
  String get consentPrivacy => 'Политикой конфиденциальности';

  @override
  String get consentSuffix => '';

  @override
  String get consentAccept => 'Согласен, отправить код';

  @override
  String get otpTitle => 'Введите код';

  @override
  String otpSubtitle(String phone) {
    return 'Мы отправили 5-значный код на $phone';
  }

  @override
  String get otpChangeNumber => 'Изменить номер';

  @override
  String otpResendIn(String time) {
    return 'Отправить повторно: $time';
  }

  @override
  String get otpResend => 'Отправить код повторно';

  @override
  String get otpResent => 'Новый код отправлен';

  @override
  String get otpWrong => 'Неверный код. Попробуйте ещё раз';

  @override
  String get otpExpired => 'Срок действия кода истёк. Запросите новый';

  @override
  String get otpVerifying => 'Проверяем…';

  @override
  String get profileSetupTitle => 'Давайте познакомимся';

  @override
  String get profileSetupSubtitle =>
      'Имя будет указано в заказах и коммерческих предложениях';

  @override
  String get firstName => 'Имя';

  @override
  String get lastName => 'Фамилия';

  @override
  String get firstNameRequired => 'Введите имя';

  @override
  String get save => 'Сохранить';

  @override
  String welcome(String name) {
    return 'Добро пожаловать, $name!';
  }

  @override
  String get welcomeNoName => 'Добро пожаловать!';

  @override
  String get tabHome => 'Главная';

  @override
  String get tabCatalog => 'Каталог';

  @override
  String get tabCart => 'Корзина';

  @override
  String get tabOrders => 'Заказы';

  @override
  String get tabProfile => 'Профиль';

  @override
  String get searchHint => 'Поиск товара или модели';

  @override
  String get soonTitle => 'Скоро';

  @override
  String get soonCatalog => 'Здесь будет каталог: товары, модели и фильтры.';

  @override
  String get soonCart => 'Купить или получить КП из корзины — одной кнопкой.';

  @override
  String get soonOrders => 'Заказы, КП и отслеживание доставки — здесь.';

  @override
  String get homeHeroTitle => 'Приложение запускается';

  @override
  String get homeHeroBody =>
      'Первый этап — вход и аккаунт. Далее каталог, корзина и отслеживание.';

  @override
  String get guestTitle => 'Войдите в аккаунт';

  @override
  String get guestBody =>
      'Заказы, коммерческие предложения и статус доставки в одном месте';

  @override
  String get signIn => 'Войти';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get themeSystem => 'Как в системе';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get settingsTerms => 'Пользовательское соглашение';

  @override
  String get settingsPrivacy => 'Политика конфиденциальности';

  @override
  String get settingsSupport => 'Поддержка';

  @override
  String get signOut => 'Выйти';

  @override
  String get signOutConfirm => 'Выйти из аккаунта?';

  @override
  String get cancel => 'Отмена';

  @override
  String version(String v) {
    return 'Версия $v';
  }

  @override
  String get errNetwork => 'Нет соединения с интернетом. Проверьте подключение';

  @override
  String get errServer => 'Ошибка сервера. Попробуйте чуть позже';

  @override
  String get errTooMany => 'Слишком много попыток. Попробуйте позже';

  @override
  String get errUnknown => 'Произошла непредвиденная ошибка';

  @override
  String get retry => 'Повторить';

  @override
  String priceSum(String sum) {
    return '$sum сум';
  }

  @override
  String priceFrom(String price) {
    return 'от $price';
  }

  @override
  String get priceOnRequest => 'Узнать цену';

  @override
  String get priceOnRequestHint =>
      'Добавьте в корзину и получите КП — продавец сообщит цену в течение 1 рабочего дня';

  @override
  String get saleTag => 'Акция';

  @override
  String get homeSale => 'Товары по акции';

  @override
  String get homeNew => 'Новинки';

  @override
  String get homePopular => 'Популярное';

  @override
  String get emptyCategory => 'В этом разделе пока нет товаров';

  @override
  String get allItems => 'Все';

  @override
  String get pricedOnly => 'С ценой';

  @override
  String get sortTitle => 'Сортировка';

  @override
  String get sortPopular => 'Популярные';

  @override
  String get sortCheap => 'Дешевле';

  @override
  String get sortExpensive => 'Дороже';

  @override
  String get sortNew => 'Новые';

  @override
  String get searchNothing => 'Ничего не найдено';

  @override
  String get searchNothingHint => 'Попробуйте другое слово или название модели';

  @override
  String searchFound(int count) {
    return 'Найдено: $count';
  }

  @override
  String get searchStartHint =>
      'Ищите по названию, модели или артикулу: например, «ВЦ 4-75» или «канальный вентилятор»';

  @override
  String get searchRecent => 'Недавние запросы';

  @override
  String get clear => 'Очистить';

  @override
  String modelsCount(int count) {
    return 'Моделей: $count';
  }

  @override
  String get chooseModel => 'Выберите модель';

  @override
  String get modelLabel => 'Модель';

  @override
  String get variantsTitle => 'Варианты';

  @override
  String get descriptionTitle => 'Описание';

  @override
  String get purposeTitle => 'Назначение';

  @override
  String get sellerTitle => 'Продавец';

  @override
  String get callSeller => 'Позвонить';

  @override
  String get addToCart => 'В корзину';

  @override
  String get chooseModelFirst => 'Сначала выберите модель';

  @override
  String get addedToCart => 'Добавлено в корзину';

  @override
  String get goToCart => 'Перейти в корзину';

  @override
  String get cartEmptyTitle => 'Корзина пуста';

  @override
  String get cartEmptyBody => 'Добавьте товары — затем купите или получите КП';

  @override
  String get goToCatalog => 'В каталог';

  @override
  String get cartClearConfirm => 'Очистить корзину?';

  @override
  String get cartTotal => 'Итого';

  @override
  String cartUnpriced(int count) {
    return '+ цену $count товаров сообщит продавец';
  }

  @override
  String get checkoutOrder => 'Оформить заказ';

  @override
  String get checkoutQuote => 'Получить КП';

  @override
  String get checkoutSoonTitle => 'Оформление — в следующей версии';

  @override
  String get checkoutSoonBody =>
      'Оформление заказа и получение КП появятся в следующей версии приложения. Корзина сохранится на этом телефоне.';

  @override
  String get understood => 'Понятно';

  @override
  String get favoritesTitle => 'Избранное';

  @override
  String get favoritesEmptyTitle => 'В избранном пусто';

  @override
  String get favoritesEmptyBody => 'Нажмите ♡ на товаре — он сохранится здесь';

  @override
  String get sizesTitle => 'Размеры';

  @override
  String get markingTitle => 'Обозначение';

  @override
  String get chooseVariant => 'Выберите вариант';

  @override
  String get chooseVariantFirst => 'Сначала выберите вариант';

  @override
  String get specsTitle => 'Характеристики';

  @override
  String get specsChooseModel =>
      'Выберите модель — здесь появятся её технические характеристики';

  @override
  String get specAirflow => 'Расход воздуха';

  @override
  String get specPressure => 'Давление';

  @override
  String get checkoutOrderTitle => 'Оформление заказа';

  @override
  String get checkoutQuoteTitle => 'Запрос КП';

  @override
  String get checkoutQuoteNote =>
      'Продавец пришлёт цены в течение 1 рабочего дня. Когда КП будет готово, придёт SMS — оно появится в разделе «Заказы».';

  @override
  String get checkoutLoginTitle => 'Войдите, чтобы продолжить';

  @override
  String get checkoutLoginBody =>
      'Заказ и КП привязываются к аккаунту — статус видно в приложении';

  @override
  String get deliveryAddress => 'Адрес доставки';

  @override
  String get deliveryAddressOptional => 'Адрес доставки (необязательно)';

  @override
  String get addressLabel => 'Адрес';

  @override
  String get addressRequired => 'Укажите адрес или отметьте на карте';

  @override
  String get addressDetailsLabel => 'Подъезд, этаж, квартира, ориентир';

  @override
  String get recipientTitle => 'Получатель';

  @override
  String get recipientName => 'Имя и фамилия';

  @override
  String get companyTitle => 'Компания (необязательно)';

  @override
  String get companyName => 'Название компании';

  @override
  String get companyTin => 'ИНН';

  @override
  String get companyTinInvalid => 'ИНН состоит из 9 цифр';

  @override
  String get commentTitle => 'Комментарий';

  @override
  String get commentHint => 'Например: с монтажом, нужны грузчики';

  @override
  String get sendQuoteRequest => 'Отправить запрос КП';

  @override
  String get confirmOrder => 'Подтвердить заказ';

  @override
  String get paymentNote =>
      'Оплата продавцу: банковский перевод, карта или наличные. Продавец свяжется с вами и согласует доставку и оплату.';

  @override
  String get mapPick => 'Отметить на карте';

  @override
  String get mapChange => 'Изменить';

  @override
  String get mapMoving => 'Выберите место…';

  @override
  String get mapLoadingAddress => 'Определяем адрес…';

  @override
  String get mapConfirm => 'Этот адрес';

  @override
  String get locationOff => 'Геолокация на телефоне выключена';

  @override
  String get locationDenied => 'Нет доступа к геолокации';

  @override
  String get locationFailed => 'Не удалось определить местоположение';

  @override
  String get doneOrderTitle => 'Заказ принят';

  @override
  String get doneQuoteTitle => 'Запрос КП отправлен';

  @override
  String get doneOrderBody =>
      'Продавец скоро свяжется с вами, чтобы согласовать доставку и оплату.';

  @override
  String get doneQuoteBody =>
      'Продавец пришлёт цены в течение 1 рабочего дня. Когда КП будет готово, придёт SMS.';

  @override
  String get myOrders => 'Мои заказы';

  @override
  String get continueShopping => 'Продолжить покупки';

  @override
  String get ordersLoginTitle => 'Здесь будут ваши заказы';

  @override
  String get ordersLoginBody =>
      'Войдите, чтобы видеть заказы, КП и статус доставки';

  @override
  String get ordersEmptyTitle => 'Заказов пока нет';

  @override
  String get ordersEmptyBody =>
      'Выберите товары в каталоге — заказы и КП появятся здесь';

  @override
  String get quoteLabel => 'КП';

  @override
  String get orderLabel => 'Заказ';

  @override
  String get priceAwaited => 'Ожидается цена';

  @override
  String get statusNew => 'Новый';

  @override
  String get statusQuotePending => 'Продавец готовит цены';

  @override
  String get statusQuoteReady => 'КП готово';

  @override
  String get statusPaid => 'Оплачен';

  @override
  String get statusShipping => 'Доставляется';

  @override
  String get statusDone => 'Завершён';

  @override
  String get statusCancelled => 'Отменён';

  @override
  String itemsCount(int count) {
    return 'Товаров: $count';
  }

  @override
  String moreItems(int count) {
    return 'ещё $count';
  }

  @override
  String checkoutSplit(int count) {
    return 'Товары из $count магазинов — каждому уйдёт отдельный заказ';
  }

  @override
  String doneNumbers(String numbers) {
    return 'Номер: $numbers';
  }

  @override
  String checkoutPartial(String ids) {
    return '$ids отправлены, остальные не удалось — попробуйте ещё раз';
  }

  @override
  String get chooseOptions => 'Выбрать';

  @override
  String get searchInList => 'Поиск по списку';

  @override
  String get bannerMore => 'Подробнее';

  @override
  String inCartCount(int count) {
    return 'В корзине · $count';
  }

  @override
  String get pdfFailed =>
      'Не удалось подготовить PDF. Проверьте интернет и попробуйте снова';

  @override
  String get kpTitle => 'Коммерческое предложение';

  @override
  String get kpDate => 'Дата';

  @override
  String get kpValidUntil => 'Действует до';

  @override
  String get kpSeller => 'Продавец';

  @override
  String get kpBuyer => 'Покупатель';

  @override
  String get kpColProduct => 'Товар';

  @override
  String get kpColQty => 'Кол-во';

  @override
  String get kpColPrice => 'Цена, сум';

  @override
  String get kpColSum => 'Сумма, сум';

  @override
  String get kpUnpricedCell => 'цену сообщит продавец';

  @override
  String get kpDeliveryTerms => 'Доставка';

  @override
  String get kpPaymentTerms => 'Оплата';

  @override
  String get kpDisclaimer =>
      'Цены по курсу на дату. Окончательные условия согласуются с продавцом. Документ не является публичной офертой.';

  @override
  String get kpDownloadPdf => 'Скачать PDF';

  @override
  String get kpAccept => 'Принимаю — оформить заказ';

  @override
  String get kpAcceptConfirmTitle => 'Принять КП?';

  @override
  String get kpAccepted => 'КП принято — заказ оформлен';

  @override
  String get kpReject => 'Отклонить';

  @override
  String get kpRejectTitle => 'Отклонить КП';

  @override
  String get kpRejectHint => 'Причина (необязательно): например, дорого';

  @override
  String get kpRejected => 'КП отклонено';

  @override
  String get kpRequestAgain => 'Получить новое';

  @override
  String get kpRequestedAgain => 'Запрос отправлен продавцу';

  @override
  String get kpPreparing =>
      'Продавец готовит КП — обычно 1 рабочий день. Когда будет готово, придёт SMS.';

  @override
  String get kpExpired => 'Срок КП истёк — запросите новое';

  @override
  String get statusQuoteExpired => 'КП истекло';

  @override
  String kpAcceptConfirmBody(String total) {
    return 'Итого $total. Продавец свяжется с вами, чтобы согласовать доставку и оплату.';
  }

  @override
  String kpPartial(int count) {
    return 'Продавец готовит цены на $count товаров — когда КП будет полным, придёт SMS';
  }

  @override
  String get kpIssueNow => 'Получить КП сейчас';

  @override
  String get kpIssued => 'КП готово — товары с ценой в документе';

  @override
  String get kpTo => 'Кому:';

  @override
  String get kpToHead => 'Руководителю';

  @override
  String get kpColName => 'Наименование';

  @override
  String get kpColUnit => 'Ед. изм';

  @override
  String get kpColUnitPrice => 'Цена за шт';

  @override
  String get kpColAmount => 'Сумма';

  @override
  String get kpColVat => 'НДС 12%';

  @override
  String get kpColTotalVat => 'Сумма с учетом НДС';

  @override
  String get kpUnit => 'шт';

  @override
  String get kpTotalRow => 'Итого:';

  @override
  String get kpRegards => 'С уважением,';

  @override
  String get kpVatNote => 'Цены указаны в сумах с учетом НДС 12%.';

  @override
  String kpDated(String date) {
    return 'от $date г.';
  }

  @override
  String kpIntro(String seller) {
    return '$seller имеет возможность поставить оборудование по Вашей заявке:';
  }

  @override
  String kpValidRange(String from, String to) {
    return '*Цены на продукцию действительны от $fromг по $toг';
  }

  @override
  String kpDirectorOf(String company) {
    return 'Директор $company';
  }

  @override
  String kpHeadOf(String company) {
    return 'Руководитель $company';
  }

  @override
  String get specsEmpty => 'Характеристик нет';

  @override
  String variantsCount(int count) {
    return 'Вариантов: $count';
  }

  @override
  String orderItemsSummary(String name, int count) {
    return '$name и ещё $count';
  }

  @override
  String piecesCount(int count) {
    return '$count шт';
  }

  @override
  String get priceSheetBody =>
      'Продавец сообщит цену в КП в течение 1 рабочего дня. Если нужно быстрее — позвоните или напишите в Telegram.';

  @override
  String get priceSheetQuote => 'Получить КП — цена за 1 рабочий день';

  @override
  String get priceSheetTelegram => 'Написать в Telegram';

  @override
  String priceSheetCall(String store) {
    return 'Позвонить · $store';
  }
}
