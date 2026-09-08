import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('ar'),
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fa'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('th'),
    Locale('tr'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Car Ambient Light'**
  String get appTitle;

  /// No description provided for @bluetoothSettings.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Settings'**
  String get bluetoothSettings;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @tapToRescan.
  ///
  /// In en, this message translates to:
  /// **'Tap to rescan'**
  String get tapToRescan;

  /// No description provided for @searchingDevices.
  ///
  /// In en, this message translates to:
  /// **'Searching devices...'**
  String get searchingDevices;

  /// No description provided for @noDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get noDevicesFound;

  /// No description provided for @checkDevicePower.
  ///
  /// In en, this message translates to:
  /// **'Please check if device is powered on and Bluetooth enabled'**
  String get checkDevicePower;

  /// No description provided for @signal.
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get signal;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @confirmDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to disconnect Bluetooth?'**
  String get confirmDisconnect;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get confirm;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting to last device...'**
  String get reconnecting;

  /// No description provided for @bluetoothPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth permission denied, please enable in settings'**
  String get bluetoothPermissionDenied;

  /// No description provided for @bluetoothOff.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off, please turn on Bluetooth'**
  String get bluetoothOff;

  /// No description provided for @turningOnBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Turning on Bluetooth...'**
  String get turningOnBluetooth;

  /// No description provided for @cannotTurnOnBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Cannot turn on Bluetooth automatically, please enable manually'**
  String get cannotTurnOnBluetooth;

  /// No description provided for @scanningBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Scanning Bluetooth devices...'**
  String get scanningBluetooth;

  /// No description provided for @scanComplete.
  ///
  /// In en, this message translates to:
  /// **'Scan complete'**
  String get scanComplete;

  /// No description provided for @scanFailed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed'**
  String get scanFailed;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @bluetoothConnected.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth connected, discovering services...'**
  String get bluetoothConnected;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @readyToControl.
  ///
  /// In en, this message translates to:
  /// **'Ready, can control lights'**
  String get readyToControl;

  /// No description provided for @deviceNotReady.
  ///
  /// In en, this message translates to:
  /// **'Device not ready, please connect Bluetooth first'**
  String get deviceNotReady;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @unknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown device'**
  String get unknownDevice;

  /// No description provided for @bluetoothNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth not connected'**
  String get bluetoothNotConnected;

  /// No description provided for @pleaseConnectBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Please connect Bluetooth device first'**
  String get pleaseConnectBluetooth;

  /// No description provided for @goConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get goConnect;

  /// No description provided for @dynamicModeNoColor.
  ///
  /// In en, this message translates to:
  /// **'Color setting not supported in dynamic mode'**
  String get dynamicModeNoColor;

  /// No description provided for @slow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get slow;

  /// No description provided for @fast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fast;

  /// No description provided for @selectZone.
  ///
  /// In en, this message translates to:
  /// **'Select Zone'**
  String get selectZone;

  /// No description provided for @selectColorMode.
  ///
  /// In en, this message translates to:
  /// **'Select Color Mode'**
  String get selectColorMode;

  /// No description provided for @selectDynamicEffect.
  ///
  /// In en, this message translates to:
  /// **'Select Dynamic Effect'**
  String get selectDynamicEffect;

  /// No description provided for @rgbColorAdjust.
  ///
  /// In en, this message translates to:
  /// **'RGB Color Adjust'**
  String get rgbColorAdjust;

  /// No description provided for @userManual.
  ///
  /// In en, this message translates to:
  /// **'User Manual'**
  String get userManual;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version V1.0.0'**
  String get version;

  /// No description provided for @zoneAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get zoneAll;

  /// No description provided for @zoneFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get zoneFront;

  /// No description provided for @zoneRear.
  ///
  /// In en, this message translates to:
  /// **'Rear'**
  String get zoneRear;

  /// No description provided for @zoneDoor.
  ///
  /// In en, this message translates to:
  /// **'Door'**
  String get zoneDoor;

  /// No description provided for @zoneFoot.
  ///
  /// In en, this message translates to:
  /// **'Foot'**
  String get zoneFoot;

  /// No description provided for @zoneTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get zoneTop;

  /// No description provided for @zoneDoor1.
  ///
  /// In en, this message translates to:
  /// **'Door 1'**
  String get zoneDoor1;

  /// No description provided for @zoneDoor2.
  ///
  /// In en, this message translates to:
  /// **'Door 2'**
  String get zoneDoor2;

  /// No description provided for @zoneSaddle.
  ///
  /// In en, this message translates to:
  /// **'Saddle'**
  String get zoneSaddle;

  /// No description provided for @colorSingle.
  ///
  /// In en, this message translates to:
  /// **'Single Color'**
  String get colorSingle;

  /// No description provided for @colorSeven.
  ///
  /// In en, this message translates to:
  /// **'Seven Colors'**
  String get colorSeven;

  /// No description provided for @colorThree.
  ///
  /// In en, this message translates to:
  /// **'Three Colors'**
  String get colorThree;

  /// No description provided for @colorRedGreen.
  ///
  /// In en, this message translates to:
  /// **'Red-Green'**
  String get colorRedGreen;

  /// No description provided for @colorRedBlue.
  ///
  /// In en, this message translates to:
  /// **'Red-Blue'**
  String get colorRedBlue;

  /// No description provided for @colorGreenBlue.
  ///
  /// In en, this message translates to:
  /// **'Green-Blue'**
  String get colorGreenBlue;

  /// No description provided for @colorTwelve.
  ///
  /// In en, this message translates to:
  /// **'Twelve Colors'**
  String get colorTwelve;

  /// No description provided for @effectOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get effectOff;

  /// No description provided for @effectBreathing.
  ///
  /// In en, this message translates to:
  /// **'Breathing'**
  String get effectBreathing;

  /// No description provided for @effectJump.
  ///
  /// In en, this message translates to:
  /// **'Jump'**
  String get effectJump;

  /// No description provided for @commonColors.
  ///
  /// In en, this message translates to:
  /// **'Common Colors'**
  String get commonColors;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'de',
    'en',
    'es',
    'fa',
    'fr',
    'hi',
    'id',
    'it',
    'ja',
    'ko',
    'nl',
    'pl',
    'pt',
    'ru',
    'th',
    'tr',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fa':
      return AppLocalizationsFa();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'th':
      return AppLocalizationsTh();
    case 'tr':
      return AppLocalizationsTr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
