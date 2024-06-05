import 'package:FullVendor/screens/about_page.dart';
import 'package:FullVendor/screens/login_page.dart';
import 'package:FullVendor/screens/salesman/salesman_category_page.dart';
import 'package:FullVendor/screens/salesman/salesman_home_page.dart';
import 'package:FullVendor/screens/splash_page.dart';
import 'package:FullVendor/utils/extensions.dart';
import 'package:flutter/cupertino.dart';

import '../screens/change_password_page.dart';
import '../screens/profile_edit_page.dart';
import '../screens/profile_page.dart';
import '../screens/salesman/add_customer_page.dart';
import '../screens/salesman/customer_selection_fragment.dart';
import '../screens/salesman/order_summery_page.dart';
import '../screens/salesman/salesman_cart_page.dart';
import '../screens/salesman/salesman_history_page.dart';
import '../screens/salesman/salesman_order_details_page.dart';
import '../screens/salesman/salesman_product_page.dart';
import '../screens/sync/customer_sync_page.dart';
import '../screens/sync/offline_data_for_sync.dart';
import '../screens/warehouse/warehouse_cart_page.dart';
import '../screens/warehouse/warehouse_credit_note.dart';
import '../screens/warehouse/warehouse_history_page.dart';
import '../screens/warehouse/warehouse_home_page.dart';
import '../screens/warehouse/warehouse_inventory_control_page.dart';
import '../screens/warehouse/warehouse_inventry_order_details.dart';
import '../screens/warehouse/warehouse_order_details.dart';

final routesMap = <String, WidgetBuilder>{
  SplashScreen.routeName: (context) => const SplashScreen(),
  LoginPage.routeName: (context) => const LoginPage(),
  SalesmanHomePage.routeName: (context) => const SalesmanHomePage(),
  WarehouseHomePage.routeName: (context) => const WarehouseHomePage(),
  SalesmanCategorySelectionPage.routeName: (context) => const SalesmanCategorySelectionPage(),
  SalesmanProductPage.routeName: (context) {
    String? categoryId = context.modalRoute?.settings.arguments as String?;
    return SalesmanProductPage(categoryId: categoryId);
  },
  SalesmanHistoryPage.routeName: (context) => const SalesmanHistoryPage(),
  SalesmanOrderDetailsPage.routeName: (context) {
    String? orderId = context.modalRoute?.settings.arguments as String?;
    return SalesmanOrderDetailsPage(orderId: orderId);
  },
  SalesmanCartPage.routeName: (context) => const SalesmanCartPage(),
  CustomerSelectionFragment.routeName: (context) => const CustomerSelectionFragment(),
  AddCustomerPage.routeName: (context) => const AddCustomerPage(),
  OrderSummaryPage.routeName: (context) {
    String mode = context.modalRoute?.settings.arguments as String? ?? 'D';
    return OrderSummaryPage(orderMode: mode);
  },
  SyncPage.routeName: (context) {
    Map<String, dynamic>? params = context.modalRoute?.settings.arguments as Map<String, dynamic>?;
    bool? isForceSync = params?['isForceSync'] as bool?;
    return SyncPage(isForceSync: isForceSync ?? false);
  },
  // WarehouseSyncPage.routeName: (context) => const WarehouseSyncPage(),
  // WareHouseOrderPage.routeName: (context) => const WareHouseOrderPage(),
  WareHouseCreditPage.routeName: (context) {
    Map<String, dynamic>? params = context.modalRoute?.settings.arguments as Map<String, dynamic>?;
    String? orderId = params?['orderId'] as String?;
    bool isFromCart = params?['isFromCart'] as bool? ?? false;
    return WareHouseCreditPage(orderId: orderId, isFromCart: isFromCart);
  },
  WareHouseOrderHistoryPage.routeName: (context) {
    bool isHistory = context.modalRoute?.settings.arguments as bool? ?? true;
    return WareHouseOrderHistoryPage(isHistory: isHistory);
  },
  WareHouseInventoryPage.routeName: (context) => const WareHouseInventoryPage(),
  WarehouseOrderDetailsPage.routeName: (context) {
    String? orderId = context.modalRoute?.settings.arguments as String?;
    return WarehouseOrderDetailsPage(orderId: orderId);
  },
  WarehouseCartPage.routeName: (context) => const WarehouseCartPage(),
  ProfilePage.routeName: (context) => const ProfilePage(),
  ProfileEditPage.routeName: (context) => const ProfileEditPage(),
  UpdatePasswordPage.routeName: (context) {
    return const UpdatePasswordPage(isRestPassword: false);
  },
  UpdatePasswordPage.routeNameResetPassword: (context) {
    return const UpdatePasswordPage(isRestPassword: true);
  },
  AboutPage.routeName: (context) => const AboutPage(),
  OfflineChangeSetWidget.routeName: (context) {
    Map<String, dynamic> order = context.modalRoute?.settings.arguments as Map<String, dynamic>;
    bool isFromLogout = order['isFromLogout'] as bool;
    return OfflineChangeSetWidget(isFromLogout: isFromLogout);
  },
  InventoryOrderDetails.routeName: (context) {
    Map<String, dynamic> order = context.modalRoute?.settings.arguments as Map<String, dynamic>;
    String orderId = order['order_id'] as String;
    String orderNumber = order['order_number'] as String;
    return InventoryOrderDetails(orderId: orderId, orderNumber: orderNumber);
  }
};
