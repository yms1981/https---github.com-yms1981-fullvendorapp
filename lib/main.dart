import 'dart:io';

import 'package:FullVendor/application/theme.dart';
import 'package:FullVendor/db/shared_pref.dart';
import 'package:FullVendor/db/sql/database.dart';
import 'package:FullVendor/screens/splash_page.dart';
import 'package:FullVendor/service/background_data_refresh.dart';
import 'package:FullVendor/utils/extensions.dart';
import 'package:FullVendor/utils/notification/notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sqflite_common/src/exception.dart'
    show SqfliteDatabaseException;
import 'package:workmanager/workmanager.dart';

import 'application/application_global_keys.dart';
import 'application/router.dart';
import 'db/offline_saved_db.dart';
import 'db/sql/cart_sql_helper.dart';
import 'network/apis.dart';

void main() async {
  // App initialization
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  /// set orientation to portrait only
  // await SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  //   DeviceOrientation.portraitDown,
  // ]);
  /// DB initialization
  await FullVendorSharedPref.instance.init();
  if (!kIsWeb) {
    await FullVendorSQLDB().init();
    await OfflineSavedDB().open();
  }

  try {
    await NotificationHelper.initialize();
  } catch (e) {
    print(e);
  }
  NotificationHelper.showProgressNotification(
    progressNotifier: FullVendor.instance.downloadProgress,
  );
  NotificationHelper.showProgressNotification(
    title: "Image Sync",
    progressNotifier: FullVendor.instance.imageSyncProgress,
    notificationId: 2,
  );
  // Connectivity listener
  // await connectivityListener();
  updateCartQuantity();
  // Crash listener
  FlutterError.onError = (FlutterErrorDetails details) {
    print("FlutterError.onError");
    print(details);
  };
  // async error handler for unhandled errors
  FlutterError.presentError = (FlutterErrorDetails details) async {
    print("FlutterError.presentError");
    print(details);
  };
  PlatformDispatcher.instance.onError = (exception, stackTrace) {
    print("PlatformDispatcher.instance.onError");
    print(exception);
    print(stackTrace);
    if (exception is SqfliteDatabaseException) {
      // todo fix the database error if any struct. changes..
      FullVendor.instance.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text("Error in database ${exception.message}"),
          duration: const Duration(seconds: 5),
        ),
      );
      return true;
    }
    return false;
  };
  defaultCustomerNotifier.addListener(defaultCustomerChangeListener);

  var isIOS = Platform.isIOS;
  if (isIOS) {
    iosInfo = await deviceInfoPlugin.iosInfo;
    deviceDetails = iosInfo?.name ?? "";
    deviceDetails += ", ";
    deviceDetails += iosInfo?.identifierForVendor ?? "";
    versionName = iosInfo?.systemVersion ?? "";
    versionCode = iosInfo?.systemVersion ?? "";
  } else {
    androidInfo = await deviceInfoPlugin.androidInfo;
    deviceDetails = androidInfo?.brand ?? "";
    deviceDetails += ", ";
    deviceDetails += androidInfo?.model ?? "";
    deviceDetails += ", ";
    deviceDetails += androidInfo?.id ?? "";
  }
  var packageInfo = await PackageInfo.fromPlatform();
  versionName = packageInfo.version;
  versionCode = packageInfo.buildNumber;

  // background worker register
  Workmanager()
      .initialize(backgroundCallbackDispatcher, isInDebugMode: kDebugMode);

  /// Run app the app with english and spanish language
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('es', 'ES'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: SplashScreen.routeName,
      onGenerateRoute: (settings) {
        if (kDebugMode) {
          print("Route: ${settings.name}");
        }
        Widget Function(BuildContext)? route = routesMap[settings.name];
        if (route != null) {
          return CupertinoPageRoute(
            builder: (context) => route(context),
            settings: settings,
          );
        }
        return CupertinoPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Route not found"),
                  TextButton(
                    onPressed: () async {
                      FullVendor.instance.pushNamed(SplashScreen.routeName);
                    },
                    child: const Text("Go to Home"),
                  ),
                ],
              ),
            ),
          ),
          settings: settings,
        );
      },
      navigatorKey: FullVendor().navigationKey,
      key: FullVendor().key,
      scaffoldMessengerKey: FullVendor().scaffoldMessengerKey,
      title: 'Full Vendor',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: appPrimaryColor),
        useMaterial3: true,
      ),
    );
  }
}

Future<void> defaultCustomerChangeListener() async {
  FullVendorSharedPref.instance.defaultCustomer =
      defaultCustomerNotifier.value?.toJson() ?? {};
}

final deviceInfoPlugin = DeviceInfoPlugin();
AndroidDeviceInfo? androidInfo;
IosDeviceInfo? iosInfo;
