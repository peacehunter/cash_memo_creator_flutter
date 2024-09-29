import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en')
  ];

  /// No description provided for @savedMemos.
  ///
  /// In en, this message translates to:
  /// **'Saved Memos'**
  String get savedMemos;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @dateNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Date: Not available'**
  String get dateNotAvailable;

  /// No description provided for @deleteMemo.
  ///
  /// In en, this message translates to:
  /// **'Delete Memo'**
  String get deleteMemo;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this memo?'**
  String get confirmDelete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @generateCashMemo.
  ///
  /// In en, this message translates to:
  /// **'Generate Cash Memo'**
  String get generateCashMemo;

  /// No description provided for @noSavedMemos.
  ///
  /// In en, this message translates to:
  /// **'No saved memos'**
  String get noSavedMemos;

  /// No description provided for @customer_name.
  ///
  /// In en, this message translates to:
  /// **'Customer name'**
  String get customer_name;

  /// No description provided for @customer_address.
  ///
  /// In en, this message translates to:
  /// **'Customer address'**
  String get customer_address;

  /// No description provided for @customer_phone_number.
  ///
  /// In en, this message translates to:
  /// **'Customer phone number'**
  String get customer_phone_number;

  /// No description provided for @product_name.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get product_name;

  /// No description provided for @product_price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get product_price;

  /// No description provided for @product_quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get product_quantity;

  /// No description provided for @add_product_button_label.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get add_product_button_label;

  /// No description provided for @discount_label.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount_label;

  /// No description provided for @tax_label.
  ///
  /// In en, this message translates to:
  /// **'Vat/Tax'**
  String get tax_label;

  /// No description provided for @create_cash_memo_label.
  ///
  /// In en, this message translates to:
  /// **'Create Cash Memo'**
  String get create_cash_memo_label;

  /// No description provided for @percent_discount_label.
  ///
  /// In en, this message translates to:
  /// **'Percentage Discount'**
  String get percent_discount_label;

  /// No description provided for @select_template_label.
  ///
  /// In en, this message translates to:
  /// **'Select a Template'**
  String get select_template_label;

  /// No description provided for @template_name_1.
  ///
  /// In en, this message translates to:
  /// **'Template 1 - Classic'**
  String get template_name_1;

  /// No description provided for @template_name_2.
  ///
  /// In en, this message translates to:
  /// **'Template 2 - Modern'**
  String get template_name_2;

  /// No description provided for @template_name_3.
  ///
  /// In en, this message translates to:
  /// **'Template 3 - Minimal'**
  String get template_name_3;

  /// No description provided for @template_name_4.
  ///
  /// In en, this message translates to:
  /// **'Template 4 - Borderless'**
  String get template_name_4;

  /// No description provided for @dialog_cancel_label.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialog_cancel_label;

  /// No description provided for @pdf_company_name.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get pdf_company_name;

  /// No description provided for @cash_memo_pdf_label.
  ///
  /// In en, this message translates to:
  /// **'Cash Memo'**
  String get cash_memo_pdf_label;

  /// No description provided for @date_pdf_label.
  ///
  /// In en, this message translates to:
  /// **'Date:'**
  String get date_pdf_label;

  /// No description provided for @product_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get product_total;

  /// No description provided for @product_subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get product_subtotal;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn': return AppLocalizationsBn();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
