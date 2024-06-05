import 'dart:io';

import 'package:FullVendor/application/theme.dart';
import 'package:FullVendor/db/offline_saved_db.dart';
import 'package:FullVendor/db/shared_pref.dart';
import 'package:FullVendor/db/sql/cart_sql_helper.dart';
import 'package:FullVendor/model/login_model.dart';
import 'package:FullVendor/screens/splash_page.dart';
import 'package:FullVendor/screens/sync/offline_data_for_sync.dart';
import 'package:FullVendor/utils/extensions.dart';
import 'package:FullVendor/utils/notification/notifications.dart';
import 'package:FullVendor/widgets/app_theme_widget.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';

import '../application/application_global_keys.dart';
import '../db/synced_db.dart';
import '../generated/assets.dart';
import '../service/duty_service.dart';
import '../widgets/dialogs/language_selection_dialog.dart';
import '../widgets/profile_pic_header.dart';
import 'about_page.dart';
import 'change_password_page.dart';
import 'profile_page.dart';

class ProfileFragment extends StatefulWidget {
  const ProfileFragment({super.key});

  @override
  State<ProfileFragment> createState() => _SalesmanFragmentState();
}

class _SalesmanFragmentState extends State<ProfileFragment> {
  bool isNotificationSub = false;

  Future<void> checkNotificationPermission() async {
    if (isNotificationSub) {
      isNotificationSub = (await NotificationHelper.askNotificationPermission()) ?? false;
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> hasNotificationPermission() async {
    isNotificationSub = await NotificationHelper.checkIsNotificationAllowed();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    hasNotificationPermission();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      appBar: ProfileHeader(
        title: FullVendorSharedPref.instance.userType == "1" ? 'Salesman' : 'Warehouse manager',
        name: LoginDataModel.instance.info?.firstName ?? "",
        role: LoginDataModel.instance.info?.companyName ?? "",
      ),
      body: Container(
        width: double.infinity,
        decoration: fragmentBoxDecoration,
        // padding: const EdgeInsets.only(top: 16, left: 13, right: 13),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: <Widget>[
            const SizedBox(height: 16),
            FullVendorSharedPref.instance.userType == "1"
                ? settingElement(
                    title: tr('on_service'),
                    icon: Image.asset(
                      Assets.iconServiceDuty,
                      color:
                          FullVendorSharedPref.instance.isOnService ? appPrimaryColor : Colors.grey,
                    ),
                    trailing: CupertinoSwitch(
                      value: FullVendorSharedPref.instance.isOnService,
                      onChanged: onDutyStatusChanges,
                      activeColor: appPrimaryColor,
                    ),
                    onTap: () async {},
                  )
                : const SizedBox(),
            settingElement(
              title: tr('profile'),
              icon: Image.asset(Assets.iconPersonalInfo),
              onTap: () async {
                await FullVendor.instance.pushNamed(ProfilePage.routeName);
                setState(() {});
              },
            ),
            settingElement(
              title: tr('change_password'),
              icon: Image.asset(Assets.iconPassword),
              onTap: () async {
                await FullVendor.instance.pushNamed(UpdatePasswordPage.routeName);
                setState(() {});
              },
            ),
            settingElement(
              title: tr('switch_language'),
              icon: Image.asset(Assets.iconLanguage),
              onTap: () async {
                await selectLanguage(context: context);
              },
            ),
            settingElement(
              title: tr('about'),
              icon: Image.asset(Assets.iconAbout),
              onTap: () async {
                await FullVendor.instance.pushNamed(AboutPage.routeName);
              },
            ),
            settingElement(
              title: "Push notification",
              icon: Image.asset(Assets.iconNotifications),
              trailing: CupertinoSwitch(
                value: isNotificationSub,
                onChanged: (value) async {
                  isNotificationSub = value;
                  if (value) {
                    await checkNotificationPermission();
                  }
                  FullVendorSharedPref.instance.isNotificationSub = value;
                  if (!mounted) return;
                  setState(() {});
                },
                activeColor: appPrimaryColor,
              ),
              onTap: () async {},
            ),
            settingElement(
              title: tr('logout'),
              icon: Image.asset(Assets.iconLogout),
              onTap: () async {
                var isConnected = (await Connectivity().checkConnectivity()).firstOrNull ==
                        ConnectivityResult.mobile ||
                    (await Connectivity().checkConnectivity()).firstOrNull ==
                        ConnectivityResult.wifi;
                if (!context.mounted) return;
                if (!isConnected) {
                  await noInternetConnection(context);
                  Fluttertoast.showToast(msg: tr('no_internet'));
                  return;
                }
                var pendingOrders = await OfflineSavedDB.instance.offlineChangeSetCount();
                if (!context.mounted) return;
                if (pendingOrders > 0) {
                  showAlertForPendingSync(pendingOrders, context);
                  return;
                }
                if (!context.mounted) return;
                bool isLogout = await _confirmLogout(context: context);
                String username = FullVendorSharedPref.instance.email;
                String password = FullVendorSharedPref.instance.password;
                String usertype = FullVendorSharedPref.instance.userType;

                if (!isLogout) return;
                print("logged out");
                FullVendorSharedPref.instance.isLoggedIn = false;
                //if (isConnected) {
                SyncedDB.instance.closeDatabase();
                SyncedDB.instance.deleteDatabase();

                List<String> files = await listFilesInDBDirectory();
                for (String file in files) {
                  try {
                    if (kDebugMode) {
                      print(file);
                    }
                    File(file).delete();
                    // ignore: empty_catches
                  } catch (e) {
                    if (kDebugMode) {
                      print(e);
                    }
                  }
                }
                //}
                await clearCart();
                await FullVendorSharedPref.instance.clear();
                //clear customer selection
                defaultCustomerNotifier.value = null;
                // clear login details
                LoginDataModel.instanceValue = null;
                // setting back the last login details
                FullVendorSharedPref.instance.email = username;
                FullVendorSharedPref.instance.password = password;
                FullVendorSharedPref.instance.userType = usertype;
                FullVendor.instance.routeReplace(SplashScreen.routeName);
              },
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget settingElement({
    required String title,
    required Widget icon,
    required VoidCallback onTap,
    bool showDivider = true,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        splashColor: appPrimaryColor,
        highlightColor: appPrimaryColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(width: 24, height: 24, child: icon),
                const SizedBox(width: 20),
                Text(
                  title,
                  style: context.appTextTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 16),
            if (showDivider) const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5E5)),
          ],
        ),
      ),
    );
  }

  Future<void> onDutyStatusChanges(bool value) async {
    if (!value) {
      FullVendorSharedPref.instance.isOnService = value;
      DutyService.instance.stopService();
      if (!mounted) return;
      setState(() {});
      return;
    }
    isNotificationSub = true;
    await checkNotificationPermission();
    if (!isNotificationSub) {
      if (!mounted) return;
      setState(() {});
      Fluttertoast.showToast(msg: tr('notification_permission_denied'));
      return;
    }
    var isLocationPermission = await isLocationPermissionGranted();
    if (!isLocationPermission) {
      await askLocationPermission();
    }
    isLocationPermission = await isLocationPermissionGranted();
    if (!isLocationPermission) {
      if (!mounted) return;
      Fluttertoast.showToast(msg: tr('location_permission_denied'));
      setState(() {});
      return;
    }
    await DutyService.instance.startService();
    FullVendorSharedPref.instance.isOnService = value;
    if (!mounted) return;
    setState(() {});
  }
}

Future<bool> _confirmLogout({required BuildContext context}) async {
  bool? isLogout = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        tr('login'),
        style: context.appTextTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      content: Text(
        tr('logout_warning'),
        style: context.appTextTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      actions: [
        MaterialButton(
          color: appPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            tr('cancel'),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(tr('logout')),
        ),
      ],
    ),
  );
  return isLogout ?? false;
}

Future<void> noInternetConnection(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        tr('no_internet_connection'),
        style: context.appTextTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      content: Text(
        tr('no_internet_warning'),
        style: context.appTextTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      actions: [
        MaterialButton(
          color: appPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          onPressed: () => Navigator.pop(context),
          child: Text(
            tr('ok'),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

Future<void> showAlertForPendingSync(int count, BuildContext context) async {
  await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            tr('pending_sync'),
            style: context.appTextTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          content: Text(
            tr('pending_sync_warning', args: [count.toString()]),
            style: context.appTextTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w400, fontSize: 14),
          ),
          actions: [
            MaterialButton(
              color: appPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              onPressed: () {
                Navigator.pop(context);
                Map<String, dynamic> data = {"isFromLogout": true};
                FullVendor.instance.pushNamed(OfflineChangeSetWidget.routeName, parameters: data);
              },
              child: Text(
                tr('ok'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      });
}

Future<bool> isLocationPermissionGranted() async {
  var locationPermission = await Geolocator.checkPermission();
  var isGranted = locationPermission == LocationPermission.whileInUse ||
      locationPermission == LocationPermission.always;
  return isGranted;
}

Future<void> askLocationPermission() async {
  var locationPermission = await Geolocator.checkPermission();
  if (locationPermission == LocationPermission.denied) {
    await Geolocator.requestPermission();
  }
}
