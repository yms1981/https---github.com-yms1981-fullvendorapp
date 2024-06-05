import 'dart:convert';

import 'package:FullVendor/db/synced_db.dart';
import 'package:FullVendor/network/apis.dart';
import 'package:FullVendor/screens/salesman/salesman_order_details_page.dart';
import 'package:FullVendor/widgets/refresh_indicator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../application/application_global_keys.dart';
import '../../application/theme.dart';
import '../../model/order_history_data_model.dart';
import '../../utils/extensions.dart';
import '../../widgets/app_theme_widget.dart';
import '../../widgets/salesman/salesman_fragment_header_widget.dart';
import '../../widgets/salesman/salesman_profile_widget.dart';

class SalesmanHistoryPage extends StatefulWidget {
  const SalesmanHistoryPage({super.key});

  static const String routeName = '/salesman/history';

  @override
  State<SalesmanHistoryPage> createState() => _SalesmanHistoryPageState();
}

class _SalesmanHistoryPageState extends State<SalesmanHistoryPage> {
  OrdersHistoryDataModel? ordersHistoryDataModel;
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    defaultCustomerNotifier.addListener(onCustomerChange);
  }

  @override
  void dispose() {
    defaultCustomerNotifier.removeListener(onCustomerChange);
    super.dispose();
  }

  Future<void> onCustomerChange() async {
    refreshIndicatorKey.currentState?.show();
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      appBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SalesmanTopBar(
            title: tr('order_history'),
            onBackPress: () => Navigator.pop(context),
          ),
          const SalesmanProfileWidget(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FullVendorRefreshIndicator(
          onRefresh: loadLocalOrderHistory,
          refreshIndicatorKey: refreshIndicatorKey,
          child: ordersHistoryDataModel == null
              ? const Center(child: CircularProgressIndicator())
              : ordersHistoryDataModel!.orderList!.isEmpty
                  ? Center(child: Text(tr('no_order_history')))
                  : ListView.builder(
                      itemCount: ordersHistoryDataModel?.orderList?.length ?? 0,
                      itemBuilder: (context, index) {
                        return historyListElement(
                          ordersHistoryDataModel!.orderList![index],
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Widget historyListElement(OrderList order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 5),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      Text(order.businessName ?? ''),
                      const SizedBox(height: 10),
                      Text(order.name ?? ''),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(order.created ?? ''),
                    Text(
                      '\$${order.orderedTotal ?? ''}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 0),
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
                    SalesmanOrderDetailsPage.routeName,
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

  ///Function to load order history from apis
  Future<void> loadOrderHistoryFromApis() async {
    dynamic response = await Apis().loadOrderHistory();
    if (!mounted) return;
    List<dynamic> responseData = response['order_list'];
    ordersHistoryDataModel = OrdersHistoryDataModel();
    ordersHistoryDataModel!.orderList = [];
    for (Map<String, dynamic> result in responseData) {
      ordersHistoryDataModel!.orderList!.add(OrderList.fromJson(result));
    }
    if (!mounted) return;
    setState(() {});
    if (kDebugMode) {
      print("API RESPONSE ->>> ${jsonEncode(response)}");
    }
  }

  Future<void> loadLocalOrderHistory() async {
    try {
      await loadOrderHistoryFromApis();
      return;
    } catch (e) {
      print(e);
    }
    List<Map<String, dynamic>> results = await SyncedDB.instance
        .readOrderHistoryList(
            customerId: defaultCustomerNotifier.value?.customerId ?? '');

    ordersHistoryDataModel = OrdersHistoryDataModel();
    ordersHistoryDataModel!.orderList = [];
    for (Map<String, dynamic> result in results) {
      ordersHistoryDataModel!.orderList!.add(OrderList.fromJson(result));
    }
    if (!mounted) return;
    setState(() {});
  }
}
