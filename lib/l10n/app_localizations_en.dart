// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Climavent';

  @override
  String get tagline => 'Ventilation and air conditioning equipment';

  @override
  String get langTitle => 'Choose your language';

  @override
  String get langSubtitle => 'You can change it later in profile settings';

  @override
  String get continueAction => 'Continue';

  @override
  String get onb1Title => 'Straight from the manufacturer';

  @override
  String get onb1Body =>
      'Fans, air conditioners, ductwork — from factories and stores across Uzbekistan.';

  @override
  String get onb2Title => 'A quote in seconds';

  @override
  String get onb2Body =>
      'Add to cart and download a PDF quote before you buy — ready for your manager\'s approval.';

  @override
  String get onb3Title => 'Track your delivery live';

  @override
  String get onb3Body =>
      'See on the map where the courier is and when they\'ll arrive.';

  @override
  String get onbNext => 'Next';

  @override
  String get onbStart => 'Get started';

  @override
  String get onbSkip => 'Skip';

  @override
  String get phoneTitle => 'Your phone number';

  @override
  String get phoneSubtitle =>
      'We\'ll text you a code to sign in or create an account';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get phoneInvalid => 'Enter the full number: 9 digits';

  @override
  String get getCode => 'Get code';

  @override
  String get later => 'Later';

  @override
  String get phoneFooter =>
      'By continuing you agree to receive an SMS. Standard carrier rates apply.';

  @override
  String get consentTitle => 'You\'re new here';

  @override
  String get consentBody =>
      'To create an account, please review and accept our terms.';

  @override
  String get consentPrefix => 'I have read and agree to the ';

  @override
  String get consentTerms => 'Terms of Use';

  @override
  String get consentAnd => ' and ';

  @override
  String get consentPrivacy => 'Privacy Policy';

  @override
  String get consentSuffix => '';

  @override
  String get consentAccept => 'Agree and send code';

  @override
  String get otpTitle => 'Enter the code';

  @override
  String otpSubtitle(String phone) {
    return 'We sent a 5-digit code to $phone';
  }

  @override
  String get otpChangeNumber => 'Change number';

  @override
  String otpResendIn(String time) {
    return 'Resend code in $time';
  }

  @override
  String get otpResend => 'Resend code';

  @override
  String get otpResent => 'A new code has been sent';

  @override
  String get otpWrong => 'Incorrect code. Please try again';

  @override
  String get otpExpired => 'The code has expired. Request a new one';

  @override
  String get otpVerifying => 'Verifying…';

  @override
  String get profileSetupTitle => 'Let\'s get acquainted';

  @override
  String get profileSetupSubtitle => 'Your name appears on orders and quotes';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get firstNameRequired => 'Enter your first name';

  @override
  String get save => 'Save';

  @override
  String welcome(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get welcomeNoName => 'Welcome!';

  @override
  String get tabHome => 'Home';

  @override
  String get tabCatalog => 'Catalog';

  @override
  String get tabCart => 'Cart';

  @override
  String get tabOrders => 'Orders';

  @override
  String get tabProfile => 'Profile';

  @override
  String get searchHint => 'Search products or models';

  @override
  String get soonTitle => 'Coming soon';

  @override
  String get soonCatalog =>
      'The catalog lives here: products, models and filters.';

  @override
  String get soonCart =>
      'Buy or get a quote from your cart — one tap either way.';

  @override
  String get soonOrders => 'Orders, quotes and delivery tracking — all here.';

  @override
  String get homeHeroTitle => 'The app is launching';

  @override
  String get homeHeroBody =>
      'Stage one is sign-in and account. Catalog, cart and tracking are next.';

  @override
  String get guestTitle => 'Sign in to your account';

  @override
  String get guestBody => 'Orders, quotes and delivery status in one place';

  @override
  String get signIn => 'Sign in';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsTerms => 'Terms of Use';

  @override
  String get settingsPrivacy => 'Privacy Policy';

  @override
  String get settingsSupport => 'Support';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirm => 'Sign out of your account?';

  @override
  String get cancel => 'Cancel';

  @override
  String version(String v) {
    return 'Version $v';
  }

  @override
  String get errNetwork => 'No internet connection. Check your network';

  @override
  String get errServer => 'Server error. Please try again shortly';

  @override
  String get errTooMany => 'Too many attempts. Please try again later';

  @override
  String get errUnknown => 'Something went wrong';

  @override
  String get retry => 'Retry';

  @override
  String priceSum(String sum) {
    return '$sum UZS';
  }

  @override
  String priceFrom(String price) {
    return 'from $price';
  }

  @override
  String get priceOnRequest => 'Get price';

  @override
  String get priceOnRequestHint =>
      'Add to cart and get a quote — the seller will price it within 1 business day';

  @override
  String get saleTag => 'Sale';

  @override
  String get homeSale => 'On sale';

  @override
  String get homeNew => 'New arrivals';

  @override
  String get homePopular => 'Popular';

  @override
  String get emptyCategory => 'No products in this section yet';

  @override
  String get allItems => 'All';

  @override
  String get pricedOnly => 'With price';

  @override
  String get sortTitle => 'Sort by';

  @override
  String get sortPopular => 'Popular';

  @override
  String get sortCheap => 'Price: low to high';

  @override
  String get sortExpensive => 'Price: high to low';

  @override
  String get sortNew => 'Newest';

  @override
  String get searchNothing => 'Nothing found';

  @override
  String get searchNothingHint => 'Try another word or a model name';

  @override
  String searchFound(int count) {
    return '$count products';
  }

  @override
  String get searchStartHint =>
      'Search by name, model or SKU, e.g. “VTs 4-75” or “duct fan”';

  @override
  String get searchRecent => 'Recent searches';

  @override
  String get clear => 'Clear';

  @override
  String modelsCount(int count) {
    return '$count models';
  }

  @override
  String get chooseModel => 'Choose a model';

  @override
  String get modelLabel => 'Model';

  @override
  String get variantsTitle => 'Variants';

  @override
  String get descriptionTitle => 'Description';

  @override
  String get purposeTitle => 'Applications';

  @override
  String get sellerTitle => 'Seller';

  @override
  String get addToCart => 'Add to cart';

  @override
  String get chooseModelFirst => 'Choose a model first';

  @override
  String get addedToCart => 'Added to cart';

  @override
  String get goToCart => 'Go to cart';

  @override
  String get cartEmptyTitle => 'Your cart is empty';

  @override
  String get cartEmptyBody => 'Add products — then buy or get a quote';

  @override
  String get goToCatalog => 'Browse catalog';

  @override
  String get cartClearConfirm => 'Clear the cart?';

  @override
  String get cartTotal => 'Total';

  @override
  String cartUnpriced(int count) {
    return '+ $count items priced by the seller';
  }

  @override
  String get checkoutOrder => 'Place order';

  @override
  String get checkoutQuote => 'Get a quote';

  @override
  String get checkoutSoonTitle => 'Checkout is coming next';

  @override
  String get checkoutSoonBody =>
      'Ordering and quotes arrive in the next app version. Your cart stays saved on this phone.';

  @override
  String get understood => 'Got it';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get favoritesEmptyTitle => 'No favorites yet';

  @override
  String get favoritesEmptyBody => 'Tap ♡ on a product to save it here';

  @override
  String get sizesTitle => 'Dimensions';

  @override
  String get markingTitle => 'Designation';

  @override
  String get chooseVariant => 'Choose a variant';

  @override
  String get chooseVariantFirst => 'Choose a variant first';

  @override
  String get specsTitle => 'Specifications';

  @override
  String get specsChooseModel => 'Choose a model to see its specifications';

  @override
  String get specAirflow => 'Airflow';

  @override
  String get specPressure => 'Pressure';

  @override
  String get checkoutOrderTitle => 'Checkout';

  @override
  String get checkoutQuoteTitle => 'Quote request';

  @override
  String get checkoutQuoteNote =>
      'We will prepare the prices within 1 business day and let you know when the quote is ready — you will find it under Orders.';

  @override
  String get checkoutLoginTitle => 'Sign in to continue';

  @override
  String get checkoutLoginBody =>
      'Orders and quotes are linked to your account so you can track them';

  @override
  String get deliveryAddress => 'Delivery address';

  @override
  String get addressLabel => 'Address';

  @override
  String get addressRequired => 'Enter an address or pick it on the map';

  @override
  String get addressDetailsLabel => 'Entrance, floor, apartment, landmark';

  @override
  String get recipientTitle => 'Recipient';

  @override
  String get recipientName => 'Full name';

  @override
  String get companyTitle => 'Company (optional)';

  @override
  String get companyName => 'Company name';

  @override
  String get companyTin => 'TIN';

  @override
  String get companyTinInvalid => 'TIN must be 9 digits';

  @override
  String get commentTitle => 'Comment';

  @override
  String get commentHint => 'E.g. with installation, loaders needed';

  @override
  String get sendQuoteRequest => 'Send quote request';

  @override
  String get confirmOrder => 'Confirm order';

  @override
  String get paymentNote =>
      'Payment goes to the seller: bank transfer, card or cash. The seller will contact you to arrange delivery and payment.';

  @override
  String get mapPick => 'Pick on map';

  @override
  String get mapChange => 'Change';

  @override
  String get mapMoving => 'Choose the spot…';

  @override
  String get mapLoadingAddress => 'Finding address…';

  @override
  String get mapConfirm => 'Use this address';

  @override
  String get locationOff => 'Location is turned off';

  @override
  String get locationDenied => 'Location permission denied';

  @override
  String get locationFailed => 'Couldn\'t get your location';

  @override
  String get doneOrderTitle => 'Order placed';

  @override
  String get doneQuoteTitle => 'Quote request sent';

  @override
  String get doneOrderBody =>
      'The seller will contact you shortly to arrange delivery and payment.';

  @override
  String get doneQuoteBody =>
      'The seller will send prices within 1 business day. You\'ll get an SMS when it\'s ready.';

  @override
  String get myOrders => 'My orders';

  @override
  String get continueShopping => 'Continue shopping';

  @override
  String get ordersLoginTitle => 'Your orders live here';

  @override
  String get ordersLoginBody =>
      'Sign in to see orders, quotes and delivery status';

  @override
  String get ordersEmptyTitle => 'No orders yet';

  @override
  String get ordersEmptyBody =>
      'Pick products in the catalog — orders and quotes will show up here';

  @override
  String get quoteLabel => 'Quote';

  @override
  String get orderLabel => 'Order';

  @override
  String get priceAwaited => 'Awaiting price';

  @override
  String get statusNew => 'New';

  @override
  String get statusQuotePending => 'Seller is pricing';

  @override
  String get statusQuoteReady => 'Quote ready';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusShipping => 'On the way';

  @override
  String get statusDone => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String itemsCount(int count) {
    return '$count items';
  }

  @override
  String moreItems(int count) {
    return '+$count more';
  }

  @override
  String checkoutSplit(int count) {
    return 'Items from $count stores — a separate order goes to each';
  }

  @override
  String doneNumbers(String numbers) {
    return 'Number: $numbers';
  }

  @override
  String checkoutPartial(String ids) {
    return '$ids sent, the rest failed — please try again';
  }

  @override
  String get chooseOptions => 'Choose';

  @override
  String get searchInList => 'Search the list';

  @override
  String get bannerMore => 'Details';

  @override
  String inCartCount(int count) {
    return 'In cart · $count';
  }

  @override
  String get pdfFailed =>
      'Couldn\'t prepare the PDF. Check your connection and try again';

  @override
  String get kpTitle => 'Commercial proposal';

  @override
  String get kpDate => 'Date';

  @override
  String get kpValidUntil => 'Valid until';

  @override
  String get kpBuyer => 'Buyer';

  @override
  String get kpColProduct => 'Product';

  @override
  String get kpColQty => 'Qty';

  @override
  String get kpColPrice => 'Price, UZS';

  @override
  String get kpColSum => 'Amount, UZS';

  @override
  String get kpUnpricedCell => 'priced by seller';

  @override
  String get kpDeliveryTerms => 'Delivery';

  @override
  String get kpPaymentTerms => 'Payment';

  @override
  String get kpDisclaimer =>
      'Prices at the exchange rate of the date. Final terms are agreed with the seller. This document is not a public offer.';

  @override
  String get kpDownloadPdf => 'Download PDF';

  @override
  String get kpAccept => 'Accept and place order';

  @override
  String get kpAcceptConfirmTitle => 'Accept the quote?';

  @override
  String get kpAccepted => 'Quote accepted — order placed';

  @override
  String get kpReject => 'Decline';

  @override
  String get kpRejectTitle => 'Decline the quote';

  @override
  String get kpRejectHint => 'Reason (optional), e.g. too expensive';

  @override
  String get kpRejected => 'Quote declined';

  @override
  String get kpRequestAgain => 'Get a new quote';

  @override
  String get kpRequestedAgain => 'Request sent to the seller';

  @override
  String get kpPreparing =>
      'Your quote is being prepared — usually 1 business day. We will let you know when it is ready.';

  @override
  String kpWaitingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pricing $count items',
      one: 'Pricing 1 item',
    );
    return '$_temp0 — we will let you know when it is ready';
  }

  @override
  String get kpExpired => 'The quote has expired — request a new one';

  @override
  String get statusQuoteExpired => 'Quote expired';

  @override
  String kpAcceptConfirmBody(String total) {
    return 'Total $total. The seller will contact you to arrange delivery and payment.';
  }

  @override
  String get kpTo => 'To:';

  @override
  String get kpToHead => 'To the head of';

  @override
  String get kpColName => 'Description';

  @override
  String get kpColUnit => 'Unit';

  @override
  String get kpColUnitPrice => 'Unit price';

  @override
  String get kpColAmount => 'Amount';

  @override
  String get kpColVat => 'VAT 12%';

  @override
  String get kpColTotalVat => 'Amount incl. VAT';

  @override
  String get kpUnit => 'pcs';

  @override
  String get kpTotalRow => 'Total:';

  @override
  String get kpRegards => 'Sincerely,';

  @override
  String get kpVatNote => 'Prices are in UZS including 12% VAT.';

  @override
  String kpDated(String date) {
    return 'dated $date';
  }

  @override
  String kpIntro(String seller) {
    return '$seller can supply the following equipment for your request:';
  }

  @override
  String kpValidRange(String from, String to) {
    return '*Prices are valid from $from to $to';
  }

  @override
  String kpDirectorOf(String company) {
    return 'Director, $company';
  }

  @override
  String kpHeadOf(String company) {
    return 'Head of $company';
  }

  @override
  String get specsEmpty => 'No specifications';

  @override
  String variantsCount(int count) {
    return '$count variants';
  }

  @override
  String orderItemsSummary(String name, int count) {
    return '$name and $count more';
  }

  @override
  String piecesCount(int count) {
    return '$count pcs';
  }

  @override
  String get priceSheetBody =>
      'The seller will price it in a quote within 1 business day. Need it faster? Message the seller right here.';

  @override
  String get priceSheetQuote => 'Get a quote — price within 1 business day';

  @override
  String get pushTokenCopied => 'Push token copied';

  @override
  String get chatWriteToStore => 'Message the store';

  @override
  String get chatsTitle => 'Messages';

  @override
  String get chatsEmptyTitle => 'No messages yet';

  @override
  String get chatsEmptyBody =>
      'Tap “Message the store” on a product page — the seller\'s reply will appear here';

  @override
  String get chatsLoginBody => 'Sign in to message stores';

  @override
  String get chatInputHint => 'Write a message…';

  @override
  String get chatTyping => 'typing…';

  @override
  String get chatConnecting => 'connecting…';

  @override
  String get chatAboutProduct => 'About this product';

  @override
  String get chatEmptyTitle => 'Ask a question';

  @override
  String get chatEmptyBody =>
      'You\'ll get a notification when the seller replies';

  @override
  String get chatQuickPrice => 'What would the price be?';

  @override
  String get chatQuickStock => 'Is it in stock?';

  @override
  String get chatQuickDelivery => 'How long does delivery take?';

  @override
  String get chatFailed => 'Not sent — tap to retry';

  @override
  String get chatUnavailable => 'Chat is coming soon';

  @override
  String get chatYou => 'You: ';

  @override
  String get chatToday => 'Today';

  @override
  String get chatYesterday => 'Yesterday';

  @override
  String get chatProductMsg => 'Question about a product';

  @override
  String get statusPacking => 'Packing';

  @override
  String get statusReady => 'Packed';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get trackTitle => 'Order status';

  @override
  String get trackCreated => 'Received';

  @override
  String get trackPacking => 'Packing';

  @override
  String get trackReady => 'Packed';

  @override
  String get trackShipping => 'On the way';

  @override
  String get trackInProgress => 'Technician at work';

  @override
  String get trackDone => 'Completed';

  @override
  String get trackCancelled => 'Cancelled';

  @override
  String get trackCourier => 'Courier';

  @override
  String get trackCourierAssigned =>
      'A courier is assigned and will head out soon';

  @override
  String trackEta(int min) {
    return '~$min min';
  }

  @override
  String get trackStale =>
      'The courier\'s location hasn\'t updated for a few minutes';

  @override
  String trackCash(String sum) {
    return 'Have $sum ready for the courier';
  }

  @override
  String get trackDelivered => 'Delivered';

  @override
  String get trackCall => 'Call';

  @override
  String get jobTitle => 'Technician service';

  @override
  String get jobWarrantyTitle => 'Warranty visit';

  @override
  String get jobPending => 'Finding a technician';

  @override
  String get jobAssigned => 'Technician assigned';

  @override
  String get jobAccepted => 'Technician confirmed';

  @override
  String get jobOnTheWay => 'Technician on the way';

  @override
  String get jobArrived => 'Technician has arrived';

  @override
  String get jobInProgress => 'Work in progress';

  @override
  String get jobCompleted => 'Completed';

  @override
  String get jobFailed => 'Not completed';

  @override
  String get jobCancelled => 'Cancelled';

  @override
  String get jobTime => 'Time';

  @override
  String get jobTimeProposed => 'Waiting for confirmation';

  @override
  String get jobTimeConfirmed => 'Confirmed';

  @override
  String get jobRescheduled => 'The technician proposed another time';

  @override
  String get jobTimeAccept => 'Accept';

  @override
  String get jobTimeReject => 'I need another time';

  @override
  String get jobTimeRejected => 'The technician will contact you';

  @override
  String get jobCode => 'Proof code';

  @override
  String get jobCodeHint =>
      'Tell the technician this code when the job is done';

  @override
  String get jobPriceTitle => 'The technician proposed a new price';

  @override
  String jobPriceWas(String sum) {
    return 'In the order: $sum';
  }

  @override
  String jobPriceRejectNote(String sum) {
    return 'If you decline, only the visit fee applies: $sum';
  }

  @override
  String get jobPriceAccept => 'Accept';

  @override
  String get jobPriceReject => 'Decline';

  @override
  String get jobPriceAccepted => 'Price accepted';

  @override
  String get jobPriceRejected => 'Price declined';

  @override
  String get jobCancel => 'Cancel service';

  @override
  String get jobCancelConfirm => 'Cancel this service?';

  @override
  String get jobCancelDone => 'Service cancelled';

  @override
  String jobWarrantyUntil(String date) {
    return 'Warranty until $date';
  }

  @override
  String get jobWarrantyClaim => 'Warranty claim';

  @override
  String get jobWarrantyHint => 'What happened? Describe briefly';

  @override
  String get jobWarrantySent => 'Claim sent — the technician will contact you';

  @override
  String get jobRate => 'Rate the work';

  @override
  String get jobRateHint => 'Comment (optional)';

  @override
  String get jobRateSend => 'Send';

  @override
  String get jobRated => 'Thanks! Your rating was saved';

  @override
  String get jobYourRating => 'Your rating';

  @override
  String get jobPhotosAfter => 'Finished work';

  @override
  String get servicesTitle => 'Services';

  @override
  String get servicesHome => 'Installation and service';

  @override
  String get servicesAll => 'All';

  @override
  String get servicesEmpty => 'No services in this area yet';

  @override
  String get servicesEmptyBody => 'Try another district or service type';

  @override
  String get serviceArea => 'Area';

  @override
  String get serviceAreaPick => 'Choose your area';

  @override
  String get serviceAreaWhole => 'Whole region';

  @override
  String serviceFrom(String sum) {
    return 'from $sum';
  }

  @override
  String get serviceByQuote => 'Price on request';

  @override
  String serviceWarranty(int months) {
    return '$months-month warranty';
  }

  @override
  String serviceDuration(int min) {
    return '~$min min';
  }

  @override
  String serviceVisitFee(String sum) {
    return 'Visit fee $sum';
  }

  @override
  String serviceJobsDone(int count) {
    return '$count jobs done';
  }

  @override
  String get serviceFromNote =>
      'The technician sets the final price on site — you approve it in the app';

  @override
  String get serviceQuoteNote =>
      'The partner will calculate and send you a price';

  @override
  String get serviceChooseVariant => 'Choose a variant';

  @override
  String get serviceOrder => 'Book';

  @override
  String get serviceAskPrice => 'Request a price';

  @override
  String get serviceAbout => 'About';

  @override
  String get serviceCheckoutTitle => 'Book a service';

  @override
  String get serviceWhere => 'Where';

  @override
  String get serviceWhen => 'When';

  @override
  String get serviceWhenNote =>
      'The technician confirms or proposes another time';

  @override
  String get serviceDistrictRequired => 'Choose a district';

  @override
  String get serviceBooked => 'Booking received';

  @override
  String get serviceNotInArea =>
      'This partner doesn\'t work in the selected area';

  @override
  String get serviceToday => 'Today';

  @override
  String get serviceTomorrow => 'Tomorrow';

  @override
  String get installTitle => 'Installation';

  @override
  String get installNote =>
      'The store\'s technician installs it after delivery';

  @override
  String installFor(String name) {
    return 'For $name';
  }

  @override
  String get installVisit => 'Installation time';

  @override
  String get serviceQty => 'Quantity';

  @override
  String get serviceTimeWindow => 'Time window';

  @override
  String get serviceSummary => 'Order';

  @override
  String get serviceTimeRequired => 'Choose a convenient time';
}
