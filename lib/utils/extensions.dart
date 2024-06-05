import 'dart:io';

import 'package:FullVendor/application/application_global_keys.dart';
import 'package:FullVendor/db/shared_pref.dart';
import 'package:FullVendor/model/customer_list_data_model.dart';
import 'package:FullVendor/screens/splash_page.dart';
import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../db/offline_saved_db.dart';
import '../db/synced_db.dart';
import '../model/database_version_check_model.dart';
import '../model/login_model.dart';
import '../network/apis.dart';

// extension function on BuildContext
extension MyCustomContextExtensions on BuildContext {
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

//   themedata
  ThemeData get theme => Theme.of(this);

//   media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);

//   ModelRoute
  ModalRoute? get modalRoute => ModalRoute.of(this);

//   scaffold messenger
  ScaffoldMessengerState get scaffoldMessenger => ScaffoldMessenger.of(this);
}

extension NumberFormatting on num {
  String toStringWithoutRounding(int fractionDigits) {
    String formattedValue = toString();

    if (!formattedValue.contains('.')) {
      // If there is no decimal point, append ".0" to indicate zero decimal places
      if (fractionDigits > 0) {
        formattedValue += '.';
      }
      for (int i = 0; i < fractionDigits; i++) {
        formattedValue += '0';
      }
    } else {
      List<String> parts = formattedValue.split('.');
      // Keep only the specified fraction digits
      if (parts.length == 2 && parts[1].length > fractionDigits) {
        parts[1] = parts[1].substring(0, fractionDigits);
      } else if (parts.length == 2 && parts[1].length < fractionDigits) {
        for (int i = 0; i < fractionDigits - parts[1].length; i++) {
          parts[1] += '0';
        }
      }
      if (fractionDigits > 0) {
        formattedValue = parts.join('.');
      } else {
        formattedValue = parts[0];
      }
    }

    return formattedValue;
  }
}

extension DecimalFormatting on Decimal {
  String toDecimalFormat({int fractionDigits = 2, bool removeTrailingZeros = false}) {
    String formattedValue = toString();

    if (!formattedValue.contains('.')) {
      // If there is no decimal point, append ".0" to indicate zero decimal places
      if (fractionDigits > 0) {
        formattedValue += '.';
      }
      for (int i = 0; i < fractionDigits; i++) {
        formattedValue += '0';
      }
    } else {
      List<String> parts = formattedValue.split('.');
      // Keep only the specified fraction digits
      if (parts.length == 2 && parts[1].length > fractionDigits) {
        parts[1] = parts[1].substring(0, fractionDigits);
      } else if (parts.length == 2 && parts[1].length < fractionDigits) {
        for (int i = 0; i < fractionDigits - parts[1].length; i++) {
          parts[1] += '0';
        }
      }
      if (fractionDigits > 0) {
        formattedValue = parts.join('.');
      } else {
        formattedValue = parts[0];
      }
    }

    if (removeTrailingZeros) {
      // Remove trailing zeros
      formattedValue = formattedValue.replaceAll(RegExp(r'0+$'), '');
      // Remove the decimal point if there are no decimal places
      formattedValue = formattedValue.replaceAll(RegExp(r'\.$'), '');
    }
    return formattedValue;
  }
}

extension MediaQueryExtension on BuildContext {
  // Extension method for app theme
  ThemeData get appTheme => Theme.of(this);

  // Extension method for app theme colors Scheme
  ColorScheme get appPrimaryColor => appTheme.colorScheme;

  // typography
  TextTheme get appTextTheme => appTheme.textTheme;

  // Extension method to easily access MediaQuery data
  MediaQueryData get mediaQueryData => MediaQuery.of(this);

  // Custom methods to access specific MediaQuery properties
  double get screenWidth => mediaQueryData.size.width;
  double get screenHeight => mediaQueryData.size.height;

  double get statusBarHeight => mediaQueryData.padding.top;
  double get navigationBarHeight => mediaQueryData.padding.bottom;
}

/// function to get the root dir of application that is safe to store data,
/// such as database, shared preference, etc.
/// in android it is /data/data/<package_name>
/// in ios it is /<app_name>/Library/Application
Future<Directory> dbDirectory() async {
  // ask for file access permission if want to save data to download forlder
  final Directory path = //(await getDownloadsDirectory()) ??
      await getApplicationDocumentsDirectory();
  return path;
}

Future<VersionCheckModel> isDBUpdateAvailable({
  bool allowMicroUpdate = false,
}) async {
  // String lastDataBaseVersion = '';
  String lastSyncedDate = '';
  VersionCheckModel versionCheckModel = VersionCheckModel();
  try {
    Map<String, dynamic> value = await SyncedDB.instance.getSyncInfo();
    // lastDataBaseVersion = value['version']?.toString() ?? '';
    lastSyncedDate = value['fecha'] ?? '';
    lastSyncedDate = FullVendorSharedPref.instance.lastDbUpdateCheck;
  } catch (e) {
    versionCheckModel.isUpdateAvailable = true;
    return versionCheckModel;
  }
  List<String> dateParts = lastSyncedDate.split('/');
  int? month = int.tryParse(dateParts.elementAtOrNull(1) ?? "0") ?? 0;
  int? day = int.tryParse(dateParts.elementAtOrNull(0) ?? "0") ?? 0;
  int? year = int.tryParse(dateParts.elementAtOrNull(2) ?? "0") ?? 0;

  DateTime lastSyncedDateTime = DateTime(year, month, day);
  DateTime currentDate = DateTime.now();
  int differenceInDays = currentDate.difference(lastSyncedDateTime).inDays;
  if (differenceInDays > 7) {
    versionCheckModel.isUpdateAvailable = true;
    return versionCheckModel;
  } else {
    var lastUpdatedOn = FullVendorSharedPref.instance.lastMicroUpdatedOn;
    DateTime lastMicroUpdateOn = DateTime.fromMillisecondsSinceEpoch(lastUpdatedOn);
    var differenceInHours = currentDate.difference(lastMicroUpdateOn).inHours;
    var canUpdate = allowMicroUpdate && differenceInHours > 1;
    versionCheckModel.isUpdateAvailable = canUpdate;
    versionCheckModel.isMicroUpdateAvailable = canUpdate;
    return versionCheckModel;
  }
}

Customer? _defaultCustomer = FullVendorSharedPref.instance.defaultCustomer.isEmpty
    ? null
    : Customer.fromJson(FullVendorSharedPref.instance.defaultCustomer);

final ValueNotifier<Customer?> defaultCustomerNotifier = ValueNotifier(_defaultCustomer);

///function to validate the session if user is logged in when no network is available.
///If user is logged in, then it will return true else false.
///If user is not logged in, then it will return false.
///
Future<dynamic> validateOfflineStartedSession(BuildContext context) async {
  bool isLoggedIn = FullVendorSharedPref.instance.isOfflineLogin;
  if (!isLoggedIn) {
    return false;
  }
  String loginType = FullVendorSharedPref.instance.userType;
  String username = FullVendorSharedPref.instance.email;
  String password = FullVendorSharedPref.instance.password;

  try {
    dynamic response =
        await Apis().login(username: username, password: password, loginType: loginType);
    LoginDataModel? loginDataModel = LoginDataModel.fromJson(response);
    if (loginDataModel.status != "1") {
      FullVendorSharedPref.instance.isLoggedIn = true;
      FullVendorSharedPref.instance.isOfflineLogin = false;
      FullVendor.instance.pushReplacementAll(SplashScreen.routeName);
      if (!context.mounted) return;
      context.showSnackBar(loginDataModel.error ?? tr('something_went_wrong'));
      return;
    } else {
      FullVendorSharedPref.instance.isOfflineLogin = false;
      await OfflineSavedDB.instance.saveOfflineLoginData(
        email: username,
        password: password,
        userType: loginType,
        sessionData: loginDataModel,
      );
      await loginDataModel.save();
      return true;
    }
  } catch (_) {}
}

Future<List<String>> listFilesInDBDirectory() async {
  List<String> filesList = [];
  try {
    // Get the application's documents directory
    final directory = await getApplicationDocumentsDirectory();

    // List all files in the directory
    List<FileSystemEntity> files = directory.listSync();

    for (var file in files) {
      if (file is File) {
        print('File: ${file.path}');
        filesList.add(file.path);
      } else if (file is Directory) {
        print('Directory: ${file.path}');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
  return filesList;
}
