import 'dart:async';

import 'package:FullVendor/application/application_global_keys.dart';
import 'package:FullVendor/db/synced_db.dart';
import 'package:FullVendor/network/apis.dart';
import 'package:FullVendor/screens/login_page.dart';
import 'package:FullVendor/screens/salesman/salesman_home_page.dart';
import 'package:FullVendor/screens/sync/customer_sync_page.dart';
import 'package:FullVendor/screens/warehouse/warehouse_home_page.dart';
import 'package:flutter/material.dart';

import '../db/shared_pref.dart';
import '../generated/assets.dart';
import '../utils/notification/notifications.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onTap: startTimer,
          child: Image.asset(Assets.iconLogo, width: 200, height: 200),
        ),
      ),
    );
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer(const Duration(seconds: 1), nextScreenAction);
  }

  Future<void> nextScreenAction() async {
    bool isLoggedIn = FullVendorSharedPref.instance.isLoggedIn;
    while (!isLoggedIn) {
      Future.delayed(const Duration(seconds: 3));
      await FullVendor.instance.pushNamed(LoginPage.routeName);
      isLoggedIn = FullVendorSharedPref.instance.isLoggedIn;
    }
    await NotificationHelper.askNotificationPermission();
    bool isSalesman = FullVendorSharedPref.instance.userType == "1";
    dynamic versionApiResponse;
    try {
      versionApiResponse = {"version": 1};
      //versionApiResponse = await Apis().checkDBVersion();
    } catch (e) {
      versionApiResponse = {"version": 1};
    }
    int version = // 9 from is from api response
        int.tryParse(versionApiResponse['version']?.toString() ?? "1") ?? 1;
    int applicationVersionCode = int.tryParse(versionCode) ?? 1;
    // the database not necessarily compare version to application version
    if (version > applicationVersionCode) {
      //await SyncedDB.instance.deleteDatabase();
    }

    bool isDBExist = await SyncedDB.instance.isSynced();
    do {
      while (!isDBExist) {
        String path = SyncPage.routeName;
        await FullVendor.instance.pushNamed(path);
        isDBExist = await SyncedDB.instance.isSynced();

        if (isDBExist) {
          String routeName = SalesmanHomePage.routeName;
          if (!isSalesman) {
            routeName = WarehouseHomePage.routeName;
          }
          FullVendor.instance.pushReplacement(routeName);

          break;
        }
      }
      try {
        await SyncedDB.instance.openDB();
      } catch (e) {
        isDBExist = false;
      }
    } while (!isDBExist);

    // Here you run API APKUpdateVersion

    String routeName = SalesmanHomePage.routeName;
    if (!isSalesman) {
      routeName = WarehouseHomePage.routeName;
    }
    FullVendor.instance.pushReplacement(routeName);
  }
}
