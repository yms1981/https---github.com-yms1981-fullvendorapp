import 'package:FullVendor/application/theme.dart';
import 'package:FullVendor/db/synced_db.dart';
import 'package:FullVendor/screens/warehouse/warehouse_inventry_order_details.dart';
import 'package:FullVendor/widgets/refresh_indicator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../application/application_global_keys.dart';
import '../../model/inventory_order_data_model.dart';
import '../../network/apis.dart';
import '../../widgets/app_theme_widget.dart';
import '../../widgets/salesman/salesman_fragment_header_widget.dart';

class WareHouseInventoryPage extends StatefulWidget {
  static const String routeName = '/warehouse/inventory';

  const WareHouseInventoryPage({super.key});

  @override
  State<WareHouseInventoryPage> createState() => _WareHouseInventoryPageState();
}

class _WareHouseInventoryPageState extends State<WareHouseInventoryPage> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey();
  WarehouseInventoryOrderDataModel? warehouseInventoryOrderDataModel;

  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      appBar: Column(
        children: [
          SalesmanTopBar(
            title: tr('inventory_control_1_line'),
            onBackPress: () async {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: FullVendorRefreshIndicator(
        onRefresh: loadInventoryOrder,
        refreshIndicatorKey: _refreshIndicatorKey,
        child: warehouseInventoryOrderDataModel == null
            ? Center(child: Text(tr('loading')))
            : CustomScrollView(
                slivers: [
                  if (warehouseInventoryOrderDataModel!.orderList?.isEmpty ??
                      true)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            tr('no_order_history'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (warehouseInventoryOrderDataModel!.orderList?.isNotEmpty ??
                      true)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                left: 10,
                                right: 10,
                                top: 10,
                                bottom: 5,
                              ),
                              child: Text(
                                '${tr('total_orders')}: ${_getOrderCount()}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          } else if (index == _getOrderCount() + 1) {
                            return const SizedBox(height: 50);
                          }
                          index -= 1;
                          OrderList orderList =
                              warehouseInventoryOrderDataModel!
                                  .orderList![index];
                          return _orderElement(order: orderList);
                        },
                        childCount:
                            _getOrderCount() == 0 ? 1 : _getOrderCount() + 2,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  /// function to get the count
  /// of the order, return zero if null or empty
  /// else size + 1 for the header
  int _getOrderCount() {
    return warehouseInventoryOrderDataModel?.orderList?.length ?? 0;
  }

  Widget _titleValueWidget({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _orderElement({required OrderList order}) {
    // int units = 0;
    // order.productList?.forEach((element) {
    //   units += int.tryParse(element.qty ?? '0') ?? 0;
    // });
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        children: [
          _titleValueWidget(
            title: tr('customer_name'),
            value: order.businessName ?? '',
          ),
          Divider(height: 0.1, color: Colors.grey.shade100),
          _titleValueWidget(title: tr('contact_name'), value: order.name ?? ''),
          Divider(height: 0.1, color: Colors.grey.shade100),
          _titleValueWidget(
              title: tr('order_id'), value: order.orderNumber ?? ''),
          Divider(height: 0.1, color: Colors.grey.shade100),
          _titleValueWidget(title: tr('place_on'), value: order.created ?? ''),
          Divider(height: 0.1, color: Colors.grey.shade100),
          _titleValueWidget(
              title: tr('updated_on'), value: order.updated ?? ''),
          Divider(height: 0.1, color: Colors.grey.shade100),
          _titleValueWidget(
            title: tr('order_status'),
            value: order.nameStatusEnglish ?? '',
          ),
          const SizedBox(height: 10),
          MaterialButton(
            onPressed: () async {
              // InventoryOrderDetails
              await FullVendor.instance.pushNamed(
                InventoryOrderDetails.routeName,
                parameters: {
                  'order_id': order.orderId ?? '-1',
                  'order_number': order.orderNumber ?? '',
                },
              );
              _refreshIndicatorKey.currentState?.show();
            },
            color: appPrimaryColor,
            minWidth: double.infinity,
            height: 50,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            textColor: Colors.white,
            child: Text(tr('view_details')),
          )
        ],
      ),
    );
  }

  Future<void> loadInventoryOrderOnline() async {
    dynamic response = await Apis().warehouseOrderInventoryList();
    warehouseInventoryOrderDataModel =
        WarehouseInventoryOrderDataModel.fromJson(response);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> loadInventoryOrderOffline() async {
    SyncedDB syncedDB = SyncedDB.instance;
    dynamic response = await syncedDB.warehouseOrderInventoryList();
    for (int i = 0; i < response.length; i++) {
      // String customerId = response[i]['customer_id'];
      // Map<String, dynamic> customerDetails =
      //     await syncedDB.readCustomerDetails(customerId);
      // Decimal discount =
      //     Decimal.tryParse(customerDetails['discount'] ?? '0') ?? Decimal.zero;
      //
      // /// customer details
      // Map<String, dynamic> orderData = response[i];
      // response[i]['business_name'] = customerDetails['business_name'];
      // response[i]['name'] = customerDetails['name'];
      // response[i]['discount'] = discount.toDecimalFormat(fractionDigits: 2);
      // response[i]['email'] = customerDetails['email'];
      // response[i]['phone'] = customerDetails['phone'];
    }
    warehouseInventoryOrderDataModel =
        WarehouseInventoryOrderDataModel.fromJson({'order_list': response});
    if (!mounted) return;
    setState(() {});
  }

  Future<void> loadInventoryOrder() async {
    try {
      await loadInventoryOrderOnline();
      return;
    } catch (e) {
      print(e);
    }
    await loadInventoryOrderOffline();
  }
}
