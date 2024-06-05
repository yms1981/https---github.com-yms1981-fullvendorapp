import 'dart:convert';

import 'package:FullVendor/db/offline_saved_db.dart';
import 'package:FullVendor/network/apis.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';

import '../db/shared_pref.dart';

class DutyService {
  DutyService._privateConstructor() {
    isOnDuty.addListener(_dutyStatusChangeListener);
  }

  static final DutyService _instance = DutyService._privateConstructor();

  static DutyService get instance => _instance;

  factory DutyService() {
    return _instance;
  }

  /// variable to get and set the current duty status
  /// accept [bool] value
  ValueNotifier<bool> isOnDuty = ValueNotifier<bool>(FullVendorSharedPref.instance.isOnService);

  Future<void> _dutyStatusChangeListener() async {
    FullVendorSharedPref.instance.isOnService = isOnDuty.value;
  }

  Future<void> stopService() async {
    isOnDuty.value = false;
  }

  Future<void> startService() async {
    isOnDuty.value = true;
  }

  Future<void> _gpsPermissionStatusAndGPSModeChecker() async {
    var isPermissionGranted = await Geolocator.checkPermission();
    if (isPermissionGranted == LocationPermission.denied) {
      isPermissionGranted = await Geolocator.requestPermission();
    }
    var isHasPermission = false;
    if (isPermissionGranted == LocationPermission.whileInUse ||
        isPermissionGranted == LocationPermission.always) {
      isHasPermission = true;
    }
    var isGPSOn = await Geolocator.isLocationServiceEnabled();
    if (!isGPSOn && isHasPermission) {
      isGPSOn = await Geolocator.openLocationSettings();
      isGPSOn = await Geolocator.isLocationServiceEnabled();
    }
    try {
      dynamic response = await Apis().updateLocationPermissionAndGPSUpdate(
        isHasPermission: isHasPermission,
        isGPSOn: isGPSOn,
      );
      response = jsonEncode(response);
      print(response);
    } catch (e) {
      print(e);
    }
  }

  Future<void> postLocationUpdate(BuildContext context) async {
    await _gpsPermissionStatusAndGPSModeChecker();
    var isPermissionGranted = await Geolocator.checkPermission();
    if (isPermissionGranted == LocationPermission.denied ||
        isPermissionGranted == LocationPermission.deniedForever ||
        isPermissionGranted == LocationPermission.unableToDetermine) {
      return;
    }
    var position = await Geolocator.getCurrentPosition(timeLimit: const Duration(seconds: 10));
    try {
      dynamic response = await Apis().updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
      response = jsonEncode(response);
      print(response);
    } catch (e) {
      print(e);
      OfflineSavedDB.instance.insertLocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        time: position.timestamp.millisecondsSinceEpoch,
        isGPSOn: await Geolocator.isLocationServiceEnabled(),
        isLocationAllowed: isPermissionGranted == LocationPermission.whileInUse ||
            isPermissionGranted == LocationPermission.always,
      );
    }
  }
}
