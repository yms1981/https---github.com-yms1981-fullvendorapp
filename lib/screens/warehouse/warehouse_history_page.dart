import 'package:FullVendor/application/application_global_keys.dart';
import 'package:FullVendor/application/theme.dart';
import 'package:FullVendor/network/apis.dart';
import 'package:FullVendor/screens/warehouse/warehouse_order_details.dart';
import 'package:FullVendor/utils/extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../db/synced_db.dart';
import '../../model/warehouse_history_data_model.dart';
import '../../widgets/app_theme_widget.dart';
import '../../widgets/refresh_indicator.dart';
import '../../widgets/salesman/salesman_fragment_header_widget.dart';

class WareHouseOrderHistoryPage extends StatefulWidget {
  const WareHouseOrderHistoryPage({super.key, this.isHistory = true});
  static const String routeName = '/warehouse/history';
  final bool isHistory;

  @override
  State<WareHouseOrderHistoryPage> createState() =>
      _WareHouseOrderHistoryPageState();
}

class _WareHouseOrderHistoryPageState extends State<WareHouseOrderHistoryPage> {
  List<WarehouseHistoryDataModel>? ordersHistoryDataModel;
  List<WarehouseHistoryDataModel>? newOrders;
  List<WarehouseHistoryDataModel>? pendingOrders;
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKeyForNewOrder =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKeyForPendingOrder =
      GlobalKey<RefreshIndicatorState>();
  bool isHistory = true;

  @override
  void initState() {
    isHistory = widget.isHistory;
    pageController.addListener(pageChangeListener);
    super.initState();
  }

  @override
  void dispose() {
    pageController.removeListener(pageChangeListener);
    super.dispose();
  }

  void pageChangeListener() {
    currentIndex = pageController.page ?? 0.0;
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      appBar: SalesmanTopBar(
        title: isHistory ? tr("order_history") : tr('order_received_1_line'),
        onBackPress: () => Navigator.pop(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FullVendorRefreshIndicator(
          onRefresh: loadLocalOrderHistory,
          refreshIndicatorKey: refreshIndicatorKey,
          child: isHistory ? orderHistoryList() : ordersList(),
        ),
      ),
    );
  }

  Widget orderHistoryList() {
    return ordersHistoryDataModel == null
        ? const Center(child: CircularProgressIndicator())
        : ordersHistoryDataModel!.isEmpty
            ? Center(child: Text(tr('no_order_history')))
            : ListView.builder(
                itemCount: ordersHistoryDataModel?.length ?? 0,
                itemBuilder: (context, index) {
                  return historyListElement(ordersHistoryDataModel![index]);
                },
              );
  }

  final PageController pageController = PageController(initialPage: 0);
  double currentIndex = 0;

  Widget buttonWidget(Widget child, bool isSelected, VoidCallback? onTap,
      BuildContext context) {
    return MaterialButton(
      onPressed: onTap,
      color: isSelected ? appPrimaryColor : Colors.grey.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }

  Widget ordersList() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MaterialButton(
                onPressed: () {
                  if (currentIndex != 0 && currentIndex == 1) {
                    pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                color: currentIndex != 1
                    ? appPrimaryColor.withOpacity(
                        currentIndex != 0 ? (1 - currentIndex) * 0.8 : 1.0)
                    : Colors.grey.withOpacity(0.5),
                elevation: 0.1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tr('new_orders'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MaterialButton(
                onPressed: () {
                  if (currentIndex != 1 && currentIndex == 0) {
                    pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                color: currentIndex != 0
                    ? appPrimaryColor.withOpacity(
                        currentIndex != 1 ? currentIndex * 0.8 : 1.0)
                    : Colors.grey.withOpacity(0.5),
                elevation: 0.1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tr('pending_orders'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: PageView(
            controller: pageController,
            children: [
              newOrders == null
                  ? const Center(child: CircularProgressIndicator())
                  : newOrders!.isEmpty
                      ? Center(child: Text(tr('no_order_history')))
                      : FullVendorRefreshIndicator(
                          onRefresh: loadLocalOrderHistory,
                          child: ListView.builder(
                            itemCount: newOrders?.length ?? 0,
                            itemBuilder: (context, index) {
                              return historyListElement(newOrders![index]);
                            },
                          ),
                        ),
              pendingOrders == null
                  ? const Center(child: CircularProgressIndicator())
                  : FullVendorRefreshIndicator(
                      onRefresh: loadLocalOrderHistory,
                      child: pendingOrders!.isEmpty
                          ? Center(child: Text(tr('no_order_history')))
                          : ListView.builder(
                              itemCount: pendingOrders?.length ?? 0,
                              itemBuilder: (context, index) {
                                return historyListElement(
                                    pendingOrders![index]);
                              },
                            ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget historyListElement(WarehouseHistoryDataModel order) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.orderNumber ?? '',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      order.businessName ?? '',
                      style: context.appTextTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(order.name ?? ''),
                  ],
                ),
              ),
              Text(order.updated ?? ''),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('total_products')),
              Text(order.productList?.length.toStringWithoutRounding(0) ?? ''),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('total_no._of_units')),
              Text(order.totalQuantity ?? ''),
            ],
          ),
          Row(
            children: [
              Expanded(child: Text(tr('place_on'))),
              Text(order.created ?? ''),
            ],
          ),
          Row(
            children: [
              Expanded(child: Text(tr('updated_on'))),
              Text(order.updated ?? ''),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.nameStatusEnglish ?? '',
                style: textColorOfStatus(order.nameStatusEnglish),
              ),
              MaterialButton(
                onPressed: () async {
                  await FullVendor.instance.pushNamed(
                    WarehouseOrderDetailsPage.routeName,
                    parameters: order.orderId ?? '-1',
                  );
                  refreshIndicatorKey.currentState?.show();
                },
                color: appPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tr('view_details'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle textColorOfStatus(String? status) {
    if (status == 'Approved') {
      return const TextStyle(color: Color(0xFF1EA910));
    } else if (status == 'Canceled') {
      return const TextStyle(color: Color(0xFFCB4335));
    } else if (status == 'Completed') {
      return const TextStyle(color: Color(0xFF1EA910));
    } else if (status == 'Delivered') {
      return const TextStyle(color: Color(0xFFFAE5D3));
    } else if (status == 'Dispatched') {
      return const TextStyle(color: Color(0xFFABEBC6));
    } else if (status == 'In Proccess') {
      return const TextStyle(color: Color(0xFFD0ECE7));
    } else if (status == 'New') {
      return const TextStyle(color: Color(0xFF1EA910));
    } else if (status == 'Partially Completed') {
      return const TextStyle(color: Color(0xFF2E86C1));
    } else if (status == 'Pending') {
      return const TextStyle(color: Color(0xFFD0ECE7));
    } else if (status == 'Read') {
      return const TextStyle(color: Color(0xFFA9CCE3));
    } else if (status == 'Rejected') {
      return const TextStyle(color: Color(0xFFCB4335));
    } else if (status == 'Return Request') {
      return const TextStyle(color: Color(0xFF008080));
    } else if (status == 'Returned') {
      return const TextStyle(color: Color(0xFF00cff4));
    } else if (status == 'Returned by Warehouse') {
      return const TextStyle(color: Color(0xFFCB4335));
    } else if (status == 'Warehouse Assigned') {
      return const TextStyle(color: Color(0xFF138D75));
    } else if (status == 'Warehouse Completed') {
      return const TextStyle(color: Color(0xFF7D3C98));
    } else {
      return const TextStyle(color: Colors.black);
    }
  }

  Future<void> loadOrdersFromNetwork() async {
    bool isHistory = this.isHistory;
    dynamic response =
        await Apis.instance.loadWarehouseOrderHistory(isHistory: isHistory);
    if (response['status'] != "1") {
      if (mounted) {
        setState(() {
          ordersHistoryDataModel = [];
          newOrders = [];
          pendingOrders = [];
        });
      }
      return;
    }
    dynamic orderList = response['order_list'] ?? [];
    ordersHistoryDataModel = [];
    for (Map<String, dynamic> order in orderList) {
      ordersHistoryDataModel!.add(WarehouseHistoryDataModel.fromJson(order));
    }
    dynamic newOrder = response['new_order_list'] ?? [];
    newOrders = [];
    for (Map<String, dynamic> order in newOrder) {
      newOrders!.add(WarehouseHistoryDataModel.fromJson(order));
    }
    dynamic pendingOrder = response['pending_order_list'] ?? [];
    pendingOrders = [];
    for (Map<String, dynamic> order in pendingOrder) {
      pendingOrders!.add(WarehouseHistoryDataModel.fromJson(order));
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> loadLocalOrderHistory() async {
    bool isHistory = this.isHistory;
    try {
      await loadOrdersFromNetwork();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (isHistory != this.isHistory) {
          refreshIndicatorKey.currentState?.show();
        }
      });
      return;
    } catch (e) {
      print(e);
    }
    List<Map<String, dynamic>> results =
        await SyncedDB.instance.readWarehouseOrders(isHistory: isHistory);
    // String json = jsonEncode(results);
    // print(json);
    ordersHistoryDataModel = [];
    pendingOrders = [];
    newOrders = [];
    // ordersHistoryDataModel!.productList = [];

    List<WarehouseHistoryDataModel> orderList = [];
    for (Map<String, dynamic> order in results) {
      orderList.add(WarehouseHistoryDataModel.fromJson(order));
    }
    if (isHistory) {
      ordersHistoryDataModel = orderList;
    } else {
      // format date to yyyy-mm-dd
      DateTime now = DateTime.now();
      String month = now.month.toString().length == 1
          ? "0${now.month}"
          : now.month.toString();
      String formattedDate = "${now.year}-$month-${now.day}";
      List<WarehouseHistoryDataModel> newOrder = orderList
          .where((element) => element.created?.contains(formattedDate) ?? false)
          .toList();
      List<WarehouseHistoryDataModel> pendingOrder = orderList
          .where(
              (element) => !(element.created?.contains(formattedDate) ?? false))
          .toList();
      newOrders = newOrder;
      pendingOrders = pendingOrder;
    }

    if (!mounted) return;
    setState(() {});
    Future.delayed(const Duration(milliseconds: 500), () {
      if (isHistory != this.isHistory) {
        refreshIndicatorKey.currentState?.show();
      }
    });
  }
}
