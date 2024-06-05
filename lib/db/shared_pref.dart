import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Shared preferences for the FullVendor app
/// This class is used to store and retrieve data from the shared preferences
/// of the app.
///
/// Shared preferences are used to store data that is required to be persisted
/// with key-value pairs. This data is stored in the device's local storage.
class FullVendorSharedPref {
  static final FullVendorSharedPref _instance = FullVendorSharedPref._internal();
  static FullVendorSharedPref get instance => _instance;
  FullVendorSharedPref._internal();
  SharedPreferences? _sharedPref;

  SharedPreferences _sharedPreferences() {
    if (_sharedPref == null) init();
    return _sharedPref!;
  }

  Map<String, dynamic> get defaultCustomer {
    String? customerString = _sharedPreferences().getString('defaultCustomer');
    if (customerString == null || customerString.isEmpty) return {};
    return jsonDecode(_sharedPreferences().getString('defaultCustomer') ?? '{}');
  }

  int get syncDbVersion => _sharedPreferences().getInt('dbVersion') ?? 1;

  set syncDbVersion(int dbVersion) {
    _sharedPreferences().setInt('dbVersion', dbVersion);
  }

  bool get isOnService => _sharedPreferences().getBool('isOnService') ?? true;

  set isOnService(bool isOnService) {
    _sharedPreferences().setBool('isOnService', isOnService);
  }

  bool get isOfflineLogin => _sharedPreferences().getBool('isOfflineLogin') ?? false;

  set isOfflineLogin(bool isOfflineLogin) {
    _sharedPreferences().setBool('isOfflineLogin', isOfflineLogin);
  }

  bool get isNotificationSub => _sharedPreferences().getBool('isNotificationSub') ?? false;

  set isNotificationSub(bool? isNotificationSub) {
    _sharedPreferences().setBool('isNotificationSub', isNotificationSub ?? false);
  }

  int get lastMicroUpdatedOn => _sharedPreferences().getInt('lastMicroUpdatedOn') ?? 0;

  set lastMicroUpdatedOn(int lastMicroUpdatedOn) {
    _sharedPreferences().setInt('lastMicroUpdatedOn', lastMicroUpdatedOn);
  }

  set defaultCustomer(Map<dynamic, dynamic> customer) {
    _sharedPreferences().setString('defaultCustomer', jsonEncode(customer));
  }

  String get email => _sharedPreferences().getString('email') ?? '';

  set email(String email) {
    _sharedPreferences().setString('email', email);
  }

  String get password => _sharedPreferences().getString('password') ?? '';

  set password(String password) {
    _sharedPreferences().setString('password', password);
  }

  set userInfo(String userInfo) {
    _sharedPreferences().setString('userInfo', userInfo);
  }

  String get userInfo => _sharedPreferences().getString('userInfo') ?? '';

  set userType(String userType) {
    _sharedPreferences().setString('userType', userType);
  }

  String get userType => _sharedPreferences().getString('userType') ?? '';

  set isLoggedIn(bool isLoggedIn) {
    _sharedPreferences().setBool('isLoggedIn', isLoggedIn);
  }

  bool get isLoggedIn => _sharedPreferences().getBool('isLoggedIn') ?? false;

  String get orderComment => _sharedPreferences().getString('orderComment') ?? '';

  set orderComment(String orderComment) {
    _sharedPreferences().setString('orderComment', orderComment);
  }

  /// variable to store the last date and time, for the database file of the logged in user
  /// to check if the database file is updated or not.
  set lastDbUpdateCheck(String lastDbUpdateCheck) {
    _sharedPreferences().setString('lastDbUpdateCheck', lastDbUpdateCheck);
  }

  String get lastDbUpdateCheck => _sharedPreferences().getString('lastDbUpdateCheck') ?? '';

  /// function to initialize the shared preferences
  /// as this function is time consuming, it is made asynchronous
  Future<void> init() async {
    _sharedPref = await SharedPreferences.getInstance();
  }

  /// function to clear the shared preferences
  /// this function is used to clear the complete shared preferences
  /// stored in the device.
  Future<void> clear() async {
    await _sharedPreferences().clear();
  }
}
