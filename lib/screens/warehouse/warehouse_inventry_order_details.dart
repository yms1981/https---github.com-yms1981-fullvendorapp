import 'dart:async';
import 'dart:typed_data';

import 'package:FullVendor/application/theme.dart';
import 'package:FullVendor/db/offline_saved_db.dart';
import 'package:FullVendor/db/synced_db.dart';
import 'package:FullVendor/network/apis.dart';
import 'package:FullVendor/utils/extensions.dart';
import 'package:FullVendor/widgets/app_theme_widget.dart';
import 'package:FullVendor/widgets/full_vendor_cache_image_loader.dart';
import 'package:FullVendor/widgets/refresh_indicator.dart';
import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../model/inventory_order_data_model.dart';
import '../../widgets/dialogs/product_dialogs.dart';
import '../../widgets/salesman/salesman_fragment_header_widget.dart';

class InventoryOrderDetails extends StatefulWidget {
  const InventoryOrderDetails({
    super.key,
    this.orderId,
    this.orderNumber,
  });

  final String? orderId;
  final String? orderNumber;
  static const String routeName = "/warehouse/inventory/details";

  @override
  State<InventoryOrderDetails> createState() => _InventoryOrderDetailsState();
}

class _InventoryOrderDetailsState extends State<InventoryOrderDetails> {
  OrderList? order;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey();

  Future<void> loadOrderDetailsOnline() async {
    dynamic response = await Apis().getOrderDetails(
      orderId: widget.orderId ?? '',
      orderNumber: widget.orderNumber ?? '',
    );
    WarehouseInventoryOrderDataModel dataModel =
        WarehouseInventoryOrderDataModel.fromJson(response);
    if (dataModel.orderList?.isNotEmpty == true) {
      order = dataModel.orderList?.first;
    }
  }

  Future<void> loadOrderDetailsOffline() async {
    dynamic response = await SyncedDB.instance.loadInventoryOrderDetails(
      widget.orderId ?? '',
    );
    if (!mounted) return;
    if (response == null) {
      context.showSnackBar(tr('something_went_wrong'));
      return;
    }
    response = {
      'order_list': [response]
    };
    WarehouseInventoryOrderDataModel dataModel =
        WarehouseInventoryOrderDataModel.fromJson(response);
    if (dataModel.orderList?.isNotEmpty == true) {
      order = dataModel.orderList?.first;
    }
  }

  Future<void> loadOrderDetails() async {
    try {
      await loadOrderDetailsOnline();
    } catch (e) {
      await loadOrderDetailsOffline();
      print(e);
    }

    var items = order?.productList ?? [];
    String orderID = order?.orderId ?? '';
    List<String> offlineUpdatedInventory =
        await OfflineSavedDB.instance.getInventoryOrderIds(orderID: orderID);
    for (var element in items) {
      String productID = element.productId ?? '';
      if (!offlineUpdatedInventory.contains(productID)) {
        continue;
      }
      int? quantity =
          await OfflineSavedDB.instance.qtyForInventory(orderID, productID);
      if (quantity != null) {
        element.qty = Decimal.fromInt(quantity).toStringAsFixed(2);
      }
      int? pack =
          await OfflineSavedDB.instance.packForInventory(orderID, productID);
      if (pack != null) {
        element.pack = Decimal.fromInt(pack).toStringAsFixed(2);
      }
    }
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      appBar: Column(
        mainAxisSize: MainAxisSize.min,
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
        refreshIndicatorKey: _refreshIndicatorKey,
        onRefresh: loadOrderDetails,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: order == null
              ? Center(
                  child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tr('loading'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                      width: 14,
                    ),
                    const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ))
              : CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    if (order != null)
                      SliverToBoxAdapter(
                        child: Text(
                          tr('order_details'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    if (order != null) _orderDetailsWidget(order!),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 15),
                    ),
                    if (order != null)
                      SliverToBoxAdapter(
                        child: Text(
                          tr('ordered_products'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    if (order != null) _orderedProduct(order!),
                  ],
                  // children: [
                  //   if (order != null) Expanded(child: _orderedProduct(order!)),
                  // ],
                ),
        ),
      ),
    );
  }

  Widget _orderedProduct(OrderList dataModel) {
    return SliverList.builder(
      itemCount: dataModel.productList?.length ?? 0,
      itemBuilder: (context, index) {
        return _productElement(dataModel.productList![index]);
      },
    );
  }

  Widget _productElement(ProductList product) {
    String qty = product.qty ?? 'X';
    String pack = product.pack ?? 'X';
    Decimal intQty = Decimal.tryParse(qty) ?? Decimal.fromInt(-2);
    Decimal intPack = Decimal.tryParse(pack) ?? Decimal.fromInt(-2);
    Decimal minusOne = Decimal.fromInt(-1);
    if (intQty == minusOne) {
      qty = 'X';
    } else {
      qty = intQty.toStringAsFixed(2);
    }
    if (intPack == minusOne) {
      pack = 'X';
    } else {
      pack = intPack.toStringAsFixed(2);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xffF8F8F8),
      ),
      child: Row(
        children: [
          Container(
            height: 100,
            width: 100,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xff000000)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: product.images?.firstOrNull?.imageBlob != null
                ? Image.memory(
                    product.images?.firstOrNull?.imageBlob ?? Uint8List(0),
                    fit: BoxFit.cover,
                  )
                : FullVendorCacheImageLoader(
                    imageUrl: product.images?.firstOrNull?.pic ?? '',
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "SKU: ${product.sku ?? ''}",
                  style: const TextStyle(
                    color: Color(0xffCC2028),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  product.name ?? '',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      // actual price
                      TextSpan(
                        text: "\$${product.salePrice ?? ''}",
                        style: const TextStyle(
                          color: Color(0xffCC2028),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tr('qty_with_colon')),
                          SizedBox(
                            height: 30,
                            width: 30,
                            child: IconButton(
                              onPressed: () async {
                                await updateQty(
                                    isIncrement: false, product: product);
                              },
                              style: ButtonStyle(
                                padding: MaterialStateProperty.all(
                                  const EdgeInsets.all(0),
                                ),
                                foregroundColor: MaterialStateProperty.all(
                                  appPrimaryColor,
                                ),
                                backgroundColor: MaterialStateProperty.all(
                                  Colors.transparent,
                                ),
                              ),
                              icon: const Icon(Icons.remove),
                            ),
                          ),
                          const SizedBox(width: 5),
                          InkWell(
                            onTap: () async {
                              double doubleQty =
                                  double.tryParse(product.qty ?? '0') ?? 0.0;
                              int qty = doubleQty.ceil();
                              int? newQuantity = await showQuantityPicker(
                                context,
                                initialQuantity: qty,
                              );
                              if (newQuantity == null) return;

                              await updateQty(
                                  isIncrement: false,
                                  product: product,
                                  qty: newQuantity.toString());
                            },
                            child: Text(qty),
                          ),
                          const SizedBox(width: 5),
                          SizedBox(
                            height: 30,
                            width: 30,
                            child: IconButton(
                              onPressed: () async {
                                await updateQty(product: product);
                              },
                              style: ButtonStyle(
                                padding: MaterialStateProperty.all(
                                  const EdgeInsets.all(0),
                                ),
                                foregroundColor: MaterialStateProperty.all(
                                  appPrimaryColor,
                                ),
                                backgroundColor: MaterialStateProperty.all(
                                  Colors.transparent,
                                ),
                              ),
                              icon: const Icon(Icons.add),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tr('packs_with_colon')),
                          SizedBox(
                            height: 30,
                            width: 30,
                            child: IconButton(
                              onPressed: () async {
                                await updatePack(
                                    isIncrement: false, product: product);
                              },
                              style: ButtonStyle(
                                padding: MaterialStateProperty.all(
                                  const EdgeInsets.all(0),
                                ),
                                foregroundColor: MaterialStateProperty.all(
                                  appPrimaryColor,
                                ),
                                backgroundColor: MaterialStateProperty.all(
                                  Colors.transparent,
                                ),
                              ),
                              icon: const Icon(Icons.remove),
                            ),
                          ),
                          const SizedBox(width: 5),
                          InkWell(
                            onTap: () async {
                              double doublePack =
                                  double.tryParse(product.pack ?? '0') ?? 0.0;
                              int pack = doublePack.ceil();
                              int? newPack = await showQuantityPicker(
                                context,
                                initialQuantity: pack,
                              );
                              if (newPack == null) return;

                              await updatePack(
                                isIncrement: false,
                                product: product,
                                pack: newPack.toString(),
                              );
                            },
                            child: Text(pack),
                          ),
                          const SizedBox(width: 5),
                          SizedBox(
                            height: 30,
                            width: 30,
                            child: IconButton(
                              onPressed: () async {
                                await updatePack(product: product);
                              },
                              style: ButtonStyle(
                                padding: MaterialStateProperty.all(
                                  const EdgeInsets.all(0),
                                ),
                                foregroundColor: MaterialStateProperty.all(
                                  appPrimaryColor,
                                ),
                                backgroundColor: MaterialStateProperty.all(
                                  Colors.transparent,
                                ),
                              ),
                              icon: const Icon(Icons.add),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> updateQty({
    bool isIncrement = true,
    String? qty,
    required ProductList product,
  }) async {
    OfflineSavedDB db = OfflineSavedDB.instance;
    int quantity = (double.tryParse(product.qty ?? '0') ?? 0.0).ceil();
    if (isIncrement) {
      quantity += 1;
    } else {
      quantity -= 1;
    }

    if (quantity < -1) quantity = -1;
    if (qty != null) {
      quantity = int.tryParse(qty) ?? quantity;
    }
    product.qty = quantity.toStringWithoutRounding(2);
    setState(() {});
    await db.insertOrUpdateInventoryOrderQty(
      orderId: widget.orderId ?? '0',
      productId: product.productId ?? '0',
      quantity: quantity,
      pack: int.tryParse(product.pack ?? '-1') ?? -1,
    );
  }

  Future<void> updatePack({
    bool isIncrement = true,
    String? pack,
    required ProductList product,
  }) async {
    OfflineSavedDB db = OfflineSavedDB.instance;
    int quantity = (double.tryParse(product.pack ?? '0') ?? 0.0).ceil();
    if (isIncrement) {
      quantity += 1;
    } else {
      quantity -= 1;
    }

    if (quantity < -1) quantity = -1;
    if (pack != null) {
      quantity = int.tryParse(pack) ?? quantity;
    }
    product.pack = quantity.toStringWithoutRounding(2);
    setState(() {});
    await db.insertOrUpdateInventoryOrderQty(
      orderId: widget.orderId ?? '0',
      productId: product.productId ?? '0',
      quantity: int.tryParse(product.qty ?? '-1') ?? -1,
      pack: quantity,
    );
  }

  Widget _orderDetailsWidget(OrderList dataModel) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xffF8F8F8),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr('business_name'),
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                      height: 1,
                      color: appPrimaryColor,
                    ),
                  ),
                ),
                Text(dataModel.businessName ?? ''),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(child: Text(tr('order_id'))),
                Text(dataModel.orderNumber ?? ''),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(child: Text(tr('place_on'))),
                Text(dataModel.created ?? ''),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text(tr('updated_on'))),
                Text(dataModel.updated ?? ''),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: MaterialButton(
                    onPressed: dispatchOrder,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 1,
                    color: appPrimaryColor,
                    child: Text(
                      tr('dispatch_goods'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> dispatchOrder() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr('dispatch_goods_in_progress')),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );

    Map<String, dynamic> data = {};
    data['delivery_status'] = '1';
    data['order_id'] = order?.orderId ?? '';
    data['order_status'] = '11';
    data['productlist'] = [];

    for (int i = 0; i < (order?.productList?.length ?? 0); i++) {
      dynamic product = {};
      product['product_id'] = order?.productList?[i].productId ?? '-1';
      product['delivered_quantity'] =
          (Decimal.tryParse(order?.productList?[i].qty ?? '0') ?? Decimal.zero)
              .toStringAsFixed(2);
      product['delivered_pack'] =
          (Decimal.tryParse(order?.productList?[i].pack ?? '0') ?? Decimal.zero)
              .toStringAsFixed(2);
      data['productlist'].add(product);
    }

    dynamic response;
    try {
      response = await Apis().dispatchOrder(data: data);
    } catch (e) {
      print(e);
      if (!mounted) return;
      Fluttertoast.showToast(msg: tr('something_went_wrong'));
      bool? save = await _showNoInternetDialog(context);
      if (save == null || !save) return;
      await OfflineSavedDB.instance.saveInventoryOrder(
        order?.orderId ?? '',
        order?.orderNumber ?? '',
        data,
      );
      await SyncedDB.instance.dispatchInventoryOrder(order?.orderId ?? '');
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      await OfflineSavedDB.instance.clearInventoryOrder(order?.orderId ?? '');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
    if (!mounted) return;
    if (response == null) {
      // context.showSnackBar(tr('something_went_wrong'));
      return;
    }
    if (response is String) {
      context.showSnackBar(response);
      return;
    }
    String status = response['status']?.toString() ?? '0';
    if (status != '1') {
      context.showSnackBar(
          response['message']?.toString() ?? tr('something_went_wrong'));
      return;
    } else {
      Navigator.of(context).pop();
    }
    _refreshIndicatorKey.currentState?.show();
  }
}

/// Function to show dialog of no internet connection
/// params: [context] is the context of the widget
Future<bool?> _showNoInternetDialog(BuildContext context) async {
  return await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          tr('network_issue'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr('save_and_place_when_online'),
              style: const TextStyle(fontSize: 15),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('ok')),
          ),
          MaterialButton(
            color: appPrimaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textColor: Colors.white,
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: Text(tr('save')),
          )
        ],
      );
    },
  );
}
