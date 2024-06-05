import 'dart:convert';

import 'package:FullVendor/application/application_global_keys.dart';
import 'package:FullVendor/application/theme.dart';
import 'package:FullVendor/db/offline_saved_db.dart';
import 'package:FullVendor/screens/sync/customer_sync_page.dart';
import 'package:FullVendor/utils/extensions.dart';
import 'package:FullVendor/widgets/app_theme_widget.dart';
import 'package:FullVendor/widgets/refresh_indicator.dart';
import 'package:FullVendor/widgets/salesman/salesman_fragment_header_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../db/synced_db.dart';
import '../../model/offline_placed_order_data_model.dart';
import '../../model/place_order_model.dart';
import '../../model/warehouse_history_data_model.dart';
import '../../model/warehouse_order_dispatch_api_model.dart';
import '../../network/apis.dart';

class OfflineChangeSetWidget extends StatefulWidget {
  const OfflineChangeSetWidget({super.key, required this.isFromLogout});
  final bool isFromLogout;
  static const String routeName = '/offline/change/set';

  @override
  State<OfflineChangeSetWidget> createState() => _OfflineChangeSetWidgetState();
}

class _OfflineChangeSetWidgetState extends State<OfflineChangeSetWidget> {
  final List<OfflineOrderDataModel> _orderPlaceRequestBodyList = [];
  final List<WarehouseHistoryDataModel> _warehouseHistoryDataModelList = [];
  final List<Map<String, dynamic>> _offlineDispatchedInventoryOrders = [];
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  Future<void> loadOfflinePlacedOrder() async {
    List<Map<String, dynamic>> offlineOrderList =
        await OfflineSavedDB.instance.getOfflineOrderData();
    _orderPlaceRequestBodyList.clear();
    for (var element in offlineOrderList) {
      _orderPlaceRequestBodyList.add(OfflineOrderDataModel.fromJson(element));
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> loadOfflineOrderModifications() async {
    List<String> modifiedOrderIds = await OfflineSavedDB.instance.getOfflineOrderModificationsIds();
    _warehouseHistoryDataModelList.clear();
    for (var element in modifiedOrderIds) {
      List<Map<String, dynamic>> offlineOrderList =
          await SyncedDB.instance.readWarehouseOrders(orderId: element, isHistory: null);
      for (var element in offlineOrderList) {
        _warehouseHistoryDataModelList.add(WarehouseHistoryDataModel.fromJson(element));
      }
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> loadOfflineDispatchOrders() async {
    List<Map<String, dynamic>> dispatchOrderIds =
        await OfflineSavedDB.instance.offlineDispatchedOrders();
    _offlineDispatchedInventoryOrders.clear();
    _offlineDispatchedInventoryOrders.addAll(dispatchOrderIds);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> loadSavedData() async {
    await loadOfflinePlacedOrder();
    await loadOfflineOrderModifications();
    await loadOfflineDispatchOrders();
  }

  String formatDateFromTimestamp(int timestamp) {
    // Convert timestamp to DateTime
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

    // Format the date as dd-MM-yyyy
    String formattedDate = DateFormat('dd-MM-yyyy').format(dateTime);

    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      appBar: SalesmanTopBar(
        title: tr('sync_offline_db'),
        onBackPress: () {
          Navigator.pop(context);
        },
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: FullVendorRefreshIndicator(
          onRefresh: loadSavedData,
          refreshIndicatorKey: _refreshIndicatorKey,
          child: ListView(
            children: [
              if (_orderPlaceRequestBodyList.isEmpty &&
                  _warehouseHistoryDataModelList.isEmpty &&
                  _offlineDispatchedInventoryOrders.isEmpty)
                Column(
                  children: [
                    Center(
                      child: Text(
                        tr('no_offline_data'),
                        style: const TextStyle(
                          color: appPrimaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    //   sync button
                    MaterialButton(
                      color: appPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      height: 40,
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.sync, color: Colors.white, size: 24),
                      onPressed: () async {
                        FullVendor.instance.pushReplacement(SyncPage.routeName);
                      },
                    ),
                  ],
                ),
              if (_orderPlaceRequestBodyList.isNotEmpty)
                Text(
                  tr('offline_place_order'),
                  style: const TextStyle(
                    color: appPrimaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return orderElementWidget(_orderPlaceRequestBodyList[index]);
                },
                itemCount: _orderPlaceRequestBodyList.length,
              ),
              if (_warehouseHistoryDataModelList.isNotEmpty)
                Text(
                  tr('offline_modified_order'),
                  style: const TextStyle(
                    color: appPrimaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return warehouseOrderEditChangeSet(_warehouseHistoryDataModelList[index]);
                },
                itemCount: _warehouseHistoryDataModelList.length,
              ),
              if (_offlineDispatchedInventoryOrders.isNotEmpty)
                Text(
                  tr('offline_dispatched_inventory_orders'),
                  style: const TextStyle(
                    color: appPrimaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return offlineInventoryDispatch(_offlineDispatchedInventoryOrders[index]);
                },
                itemCount: _offlineDispatchedInventoryOrders.length,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget orderElementWidget(OfflineOrderDataModel orderData) {
    OrderPlaceRequestBody? orderPlaceRequestBody = orderData.orderData;
    // in dd-MM-yyyy format
    String placeOn = '';
    if (orderData.orderCreateTime != null) {
      placeOn = formatDateFromTimestamp(orderData.orderCreateTime!);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          titleBodyValue(tr('business_name'), orderPlaceRequestBody?.bussName ?? ''),
          const SizedBox(height: 8),
          titleBodyValue(tr('contact_name'), orderPlaceRequestBody?.contactName ?? ''),
          const SizedBox(height: 8),
          titleBodyValue(tr('order_total'), "\$${orderPlaceRequestBody?.amount ?? ''}"),
          const SizedBox(height: 8),
          titleBodyValue(tr('place_on'), placeOn),
          const SizedBox(height: 8),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                color: appPrimaryColor,
                icon: const Icon(Icons.delete, color: appPrimaryColor, size: 24),
                onPressed: () async {
                  await OfflineSavedDB.instance.deleteOfflineOrder(orderData.orderID!);
                  _refreshIndicatorKey.currentState?.show();
                },
              ),
              MaterialButton(
                color: appPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                height: 40,
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.upload, color: Colors.white, size: 24),
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(tr('syncing')),
                        content: Text(tr('please_wait')),
                      );
                    },
                  );
                  try {
                    dynamic response;
                    if (orderData.orderMode == "D") {
                      response =
                          await Apis().placeOrder(orderPlaceRequestBody: orderData.orderData!);
                    } else if (orderData.orderMode == "C") {
                      response = await Apis()
                          .placeCreditOrder(orderPlaceRequestBody: orderData.orderData!);
                    } else {
                      response = {'error': 'Invalid tpod type'};
                    }
                    if (response['status'] != "1") {
                      String message = response['message'] ?? 'Error';
                      Fluttertoast.showToast(
                        msg: message,
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                      );
                    } else {
                      await OfflineSavedDB.instance.deleteOfflineOrder(orderData.orderID!);
                      _refreshIndicatorKey.currentState?.show();
                    }
                  } catch (e) {
                    Fluttertoast.showToast(
                      msg: tr('connection_error'),
                      toastLength: Toast.LENGTH_LONG,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIosWeb: 1,
                    );
                  }
                  if (!mounted) return;
                  Navigator.pop(context);
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget titleBodyValue(String title, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: appPrimaryColor.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(value),
      ],
    );
  }

  Widget warehouseOrderEditChangeSet(WarehouseHistoryDataModel orderData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          titleBodyValue(tr('business_name'), orderData.businessName ?? ''),
          const SizedBox(height: 8),
          titleBodyValue(tr('contact_name'), orderData.name ?? ''),
          const SizedBox(height: 8),
          titleBodyValue(tr('order_total'), "\$${orderData.totalamount ?? ''}"),
          const SizedBox(height: 8),
          titleBodyValue(tr('place_on'), orderData.created ?? ''),
          const SizedBox(height: 8),
          titleBodyValue(tr('order_status'), orderData.nameStatusEnglish ?? ''),
          const SizedBox(height: 8),
          titleBodyValue(tr('order_type'), "Warehouse Order Received"),
          const SizedBox(height: 8),
          titleBodyValue(tr('order_number'), orderData.orderNumber ?? ''),
          const SizedBox(height: 8),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                color: appPrimaryColor,
                icon: const Icon(Icons.delete, color: appPrimaryColor, size: 24),
                onPressed: () async {
                  await OfflineSavedDB.instance.deleteOfflineOrderChangeSet(orderData.orderId!);
                  _refreshIndicatorKey.currentState?.show();
                },
              ),
              MaterialButton(
                color: appPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                height: 40,
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.upload, color: Colors.white, size: 24),
                onPressed: () async {
                  await warehouseOrderEditUpdateAction(orderData);
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget offlineInventoryDispatch(Map<String, dynamic> orderData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          titleBodyValue(tr('order_id'), orderData['order_id']),
          const SizedBox(height: 8),
          titleBodyValue(tr('order_number'), orderData['order_number']),
          const SizedBox(height: 8),
          titleBodyValue(tr('order_type'), "Inventory Dispatch"),
          const SizedBox(height: 8),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                color: appPrimaryColor,
                icon: const Icon(Icons.delete, color: appPrimaryColor, size: 24),
                onPressed: () async {
                  await OfflineSavedDB.instance.deleteOfflineDispatchedOrder(orderData['order_id']);
                  _refreshIndicatorKey.currentState?.show();
                },
              ),
              MaterialButton(
                color: appPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                height: 40,
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.upload, color: Colors.white, size: 24),
                onPressed: () async {
                  await dispatchInventoryOrder(orderData);
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<void> warehouseOrderEditUpdateAction(WarehouseHistoryDataModel orderData) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(tr('syncing')),
          content: Text(tr('please_wait')),
        );
      },
    );
    List<String> editedProductIds =
        await OfflineSavedDB.instance.getEditedProductIds(orderData.orderId!);
    List<String> addedProductIds =
        await OfflineSavedDB.instance.getAddedProductIds(orderData.orderId!);

    bool addedProductTest(ProductList e) {
      return addedProductIds.contains(e.productId);
    }

    bool editedProductTest(ProductList e) {
      return editedProductIds.contains(e.productId);
    }

    String orderId = orderData.orderId ?? '';
    List<ProductList> productList = orderData.productList ?? [];
    List<ProductList> addedProducts = productList.where(addedProductTest).toList();
    List<ProductList> editedProducts = productList.where(editedProductTest).toList();

    for (var product in addedProducts) {
      try {
        var response = await Apis().editWarehouseOrderByAddingProduct(
          orderId: orderId,
          product: product,
          quantity: int.tryParse(product.qty ?? '0') ?? 0,
          ordersHistoryDataModel: orderData,
        );
        print(response);
        await OfflineSavedDB.instance.deleteAddedRecordFor(orderId, product.productId ?? '');
      } catch (e) {
        print(e);
      }
    }
    for (var product in editedProducts) {
      try {
        dynamic response = await Apis().editWarehouseOrderProductDeliverPack(
          orderId: orderId,
          product: product,
          quantity: product.deliveredQty ?? '0',
          pack: product.deliveryPack ?? '0',
        );
        print(response);
        await OfflineSavedDB.instance.deleteOfflineEditRecord(orderId, product.productId ?? '');
      } catch (e) {
        print(e);
      }
    }

    bool isDispatched = orderData.orderStatus == "11";
    if (isDispatched) {
      OrderDispatchAPIRequestModel requestModel = OrderDispatchAPIRequestModel(
        deliveryStatus: "1",
        orderId: orderId,
        orderStatus: "11",
        productlist: orderData.productList?.map((e) {
          return OrderReceivedProductList(
            productId: e.productId,
            deliveredQuantity: e.deliveredQty,
            deliveredPack: e.deliveryPack,
          );
        }).toList(),
      );
      try {
        dynamic response = await Apis().warehouseOrderDelivered(
          orderDispatchAPIRequestModel: requestModel,
        );
        if (response['status'].toString() != "1") {
          String message = response['error'] ?? tr('something_went_wrong');
          if (mounted) {
            context.showSnackBar(message);
          } else {
            Fluttertoast.showToast(msg: message);
          }
        } else {
          await OfflineSavedDB.instance.deleteOrderStatusUpdateTrack(orderId, "D");
        }
        print(response);
      } catch (e) {
        print(e);
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> dispatchInventoryOrder(Map<String, dynamic> data) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(tr('syncing')),
          content: Text(tr('please_wait')),
        );
      },
    );
    try {
      dynamic response = await Apis().dispatchOrder(data: jsonDecode(data['data']));
      if (response['status'].toString() != "1") {
        String message = response['error'] ?? tr('something_went_wrong');
        if (mounted) {
          context.showSnackBar(message);
        } else {
          Fluttertoast.showToast(msg: message);
        }
      } else {
        await OfflineSavedDB.instance.deleteOfflineDispatchedOrder(data['order_id']);
      }
      print(response);
    } catch (e) {
      print(e);
      if (!mounted) return;
      context.showSnackBar(tr('connection_error'));
    }
    if (!mounted) return;
    Navigator.pop(context);
  }
}
