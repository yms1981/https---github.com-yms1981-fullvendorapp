import 'dart:async';

import 'package:FullVendor/application/application_global_keys.dart';
import 'package:FullVendor/db/sql/cart_sql_helper.dart';
import 'package:FullVendor/screens/warehouse/warehouse_cart_page.dart';
import 'package:FullVendor/screens/warehouse/warehouse_home_fragment.dart';
import 'package:FullVendor/utils/extensions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../generated/assets.dart';
import '../profile_fragment.dart';
import '../salesman/customer_selection_fragment.dart';

class WarehouseHomePage extends StatefulWidget {
  const WarehouseHomePage({super.key});
  static const String routeName = '/warehouse/home';

  @override
  State<WarehouseHomePage> createState() => _WarehouseHomePageState();
}

class _WarehouseHomePageState extends State<WarehouseHomePage> {
  int selectedIndex = 0;
  StreamSubscription? connectivitySubscription;

  Future<void> onConnectionChange(List<ConnectivityResult> state) async {
    var isConnected = state.firstOrNull != ConnectivityResult.none;
    if (!isConnected) return;
    await validateOfflineStartedSession(context);
  }

  @override
  void initState() {
    super.initState();
    var connectivity = Connectivity();
    connectivitySubscription =
        connectivity.onConnectivityChanged.listen(onConnectionChange);
    connectivity.checkConnectivity().then(onConnectionChange);
  }

  @override
  void dispose() {
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
            label: "",
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
        ],
        onTap: (index) async {
          if (index == 1) {
            if (cartQuantityNotifier.value == 0) {
              context.showSnackBar(tr('cart_empty'));
            } else {
              defaultCustomerNotifier.value ??=
                  await FullVendor.instance.pushNamed(
                CustomerSelectionFragment.routeName,
                parameters: true,
              );
              if (defaultCustomerNotifier.value == null) return;
              await FullVendor.instance.pushNamed(WarehouseCartPage.routeName);
            }
            return;
          }
          selectedIndex = index;
          setState(() {});
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
              child: selectedIndex == 0
                  ? const WarehouseHomeFragment()
                  : const ProfileFragment(),
            ),
          ),
          Stack(
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
                      style: context.appTextTheme.bodyMedium
                          ?.copyWith(color: Colors.white, fontSize: 12),
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
          )
        ],
      ),
    );
  }
}
