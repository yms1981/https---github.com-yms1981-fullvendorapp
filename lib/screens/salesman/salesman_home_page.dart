import 'dart:async';
import 'dart:convert';

import 'package:FullVendor/application/application_global_keys.dart';
import 'package:FullVendor/db/offline_saved_db.dart';
import 'package:FullVendor/network/apis.dart';
import 'package:FullVendor/screens/profile_fragment.dart';
import 'package:FullVendor/screens/salesman/salesman_cart_page.dart';
import 'package:FullVendor/screens/salesman/salesman_home_fragment.dart';
import 'package:FullVendor/utils/extensions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../db/sql/cart_sql_helper.dart';
import '../../generated/assets.dart';
import '../../service/duty_service.dart';

class SalesmanHomePage extends StatefulWidget {
  const SalesmanHomePage({super.key});

  static const String routeName = '/salesman/home';

  @override
  State<SalesmanHomePage> createState() => _SalesmanHomePageState();
}

class _SalesmanHomePageState extends State<SalesmanHomePage> {
  int selectedIndex = 0;
  var dutyService = DutyService.instance;
  Timer? dutyListenerTimer;
  StreamSubscription? connectivitySubscription;

  Future<void> dutyListener() async {
    var isOnDuty = dutyService.isOnDuty.value;
    if (!isOnDuty) {
      dutyListenerTimer?.cancel();
      return;
    }
    dutyListenerTimer = Timer.periodic(const Duration(minutes: 5), dutyAction);
    dutyAction(dutyListenerTimer!);
  }

  Future<void> dutyAction(Timer timer) async {
    if (!mounted) return;
    dutyService.postLocationUpdate(context);
  }

  Future<void> onConnectionChange(List<ConnectivityResult> state) async {
    var isConnected = state.firstOrNull != ConnectivityResult.none;
    if (!isConnected) return;
    await validateOfflineStartedSession(context);
    var offLineSavedLocations = await OfflineSavedDB.instance.getOfflineLocations();
    if (offLineSavedLocations.isEmpty) return;
    for (var location in offLineSavedLocations) {
      dynamic response;
      try {
        var id = location.id;
        var latitude = location.latitude ?? -1;
        var longitude = location.longitude ?? -1;
        var accuracy = location.accuracy ?? -1;
        var timestamp = location.time ?? DateTime.now().millisecondsSinceEpoch;
        var dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        response = await Apis().updateLocation(
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
          timestamp: dateTime,
        );
        response = jsonEncode(response);
        print(response);
        await OfflineSavedDB.instance.deleteOfflineLocationData(id);
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  void initState() {
    dutyListener();
    dutyService.isOnDuty.addListener(dutyListener);
    var connectivity = Connectivity();
    connectivitySubscription = connectivity.onConnectivityChanged.listen(onConnectionChange);
    connectivity.checkConnectivity().then(onConnectionChange);

    super.initState();
  }

  @override
  void dispose() {
    dutyService.isOnDuty.removeListener(dutyListener);
    dutyListenerTimer?.cancel();
    connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(
            icon: ValueListenableBuilder(
              valueListenable: cartQuantityNotifier,
              builder: (context, value, child) {
                return Badge(
                  label: Text(value.toString()),
                  isLabelVisible: value != 0,
                  child: const Icon(Icons.shopping_cart),
                );
              },
            ),
            label: '',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
        ],
        onTap: (index) {
          if (index != 1) {
            selectedIndex = index;
            setState(() {});
          } else {
            if (cartQuantityNotifier.value == 0) {
              context.showSnackBar(tr('cart_empty'));
            } else {
              FullVendor.instance.pushNamed(SalesmanCartPage.routeName);
            }
          }
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
              duration: const Duration(milliseconds: 230),
              child: selectedIndex == 0 ? const SalesmanHomeFragment() : const ProfileFragment(),
            ),
          ),
          bottomImage(),
        ],
      ),
    );
  }

  Widget bottomImage() {
    return Stack(
      children: [
        Container(
          constraints: const BoxConstraints.expand(height: 70),
          child: Image.asset(Assets.imagesBottomNoteImage),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Use FullVendor for your salesforce',
                style: context.appTextTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'www.fullvendor.com',
                style: context.appTextTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
