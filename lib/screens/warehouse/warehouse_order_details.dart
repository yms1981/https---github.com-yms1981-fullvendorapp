import 'dart:async';
import 'dart:convert';

import 'package:FullVendor/application/application_global_keys.dart';
import 'package:FullVendor/db/offline_saved_db.dart';
import 'package:FullVendor/db/synced_db.dart';
import 'package:FullVendor/screens/warehouse/warehouse_credit_note.dart';
import 'package:FullVendor/utils/extensions.dart';
import 'package:FullVendor/widgets/app_theme_widget.dart';
import 'package:FullVendor/widgets/full_vendor_cache_image_loader.dart';
import 'package:FullVendor/widgets/refresh_indicator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../application/theme.dart';
import '../../model/customer_list_data_model.dart';
import '../../model/warehouse_history_data_model.dart';
import '../../model/warehouse_order_dispatch_api_model.dart';
import '../../network/apis.dart';
import '../../widgets/dialogs/product_dialogs.dart';
import '../../widgets/dialogs/save_offline_and_place_when_online_dialog.dart';
import '../../widgets/salesman/salesman_fragment_header_widget.dart';

class WarehouseOrderDetailsPage extends StatefulWidget {
  const WarehouseOrderDetailsPage({super.key, this.orderId});

  static const routeName = '/warehouse/order-details';
  static ValueNotifier<List<ProductList>>? addedProduct;
  final String? orderId;

  @override
  State<WarehouseOrderDetailsPage> createState() =>
      _WarehouseOrderDetailsPageState();
}

class _WarehouseOrderDetailsPageState extends State<WarehouseOrderDetailsPage> {
  WarehouseHistoryDataModel? ordersHistoryDataModel;
  Customer? customerDataModel;
  GlobalKey<RefreshIndicatorState> refreshIndicatorKey = GlobalKey();
  bool isNetworkAvailable = true;
  bool isAPIRequestInProgress = false;
  var saveOffline = false;
  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;

  @override
  void initState() {
    super.initState();
    connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((event) {
      isNetworkAvailable = event.firstOrNull != ConnectivityResult.none;
      setState(() {});
    });
    Connectivity().checkConnectivity().then((value) async {
      // await Future.delayed(const Duration(seconds: 1));
      isNetworkAvailable = value.firstOrNull != ConnectivityResult.none;
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      appBar: SalesmanTopBar(
        title: tr('order_details_with_order_id', args: [widget.orderId ?? '']),
        onBackPress: () => Navigator.pop(context),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: FullVendorRefreshIndicator(
          onRefresh: loadData,
          refreshIndicatorKey: refreshIndicatorKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              if (ordersHistoryDataModel != null)
                Text(
                  tr('order_details'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              if (ordersHistoryDataModel != null)
                _orderDetailsWidget(ordersHistoryDataModel!),
              _noInternetWidget(),
              const SizedBox(height: 20),
              if (customerDataModel != null)
                Text(
                  tr('shipping_address'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              if (customerDataModel != null)
                _addressToShipWidget(customerDataModel!),
              const SizedBox(height: 20),
              if (ordersHistoryDataModel != null)
                Text(
                  tr('ordered_products'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              if (ordersHistoryDataModel != null)
                _orderedProduct(ordersHistoryDataModel!),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noInternetWidget() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 530),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xfffdd7d7),
        ),
        padding: isNetworkAvailable
            ? null
            : const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: isNetworkAvailable
            ? const SizedBox()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wifi_off_outlined, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tr('no_internet_connection'),
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    tr('no_internet_connection_message'),
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontSize: 12,
                    ),
                  )
                ],
              ),
      ),
    );
  }

  Widget _orderedProduct(WarehouseHistoryDataModel dataModel) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: List.generate(dataModel.productList?.length ?? 0, (index) {
          return _productElement(dataModel.productList![index]);
        }),
      ),
    );
  }

  Widget _productElement(ProductList product) {
    bool isEdited = false;
    if (product.deliveredQty != "0" && product.deliveryPack != "0") {
      isEdited = true;
    }
    String deliveredQty = product.deliveredQty ?? '0';
    if (deliveredQty == "-1") {
      deliveredQty = "X";
    } else {
      Decimal qty = Decimal.tryParse(deliveredQty) ?? Decimal.zero;
      deliveredQty = qty.toStringAsFixed(0);
    }
    String deliveryPack = product.deliveryPack ?? '0';
    if (deliveryPack == "-1") {
      deliveryPack = "X";
    } else {
      Decimal pack = Decimal.tryParse(deliveryPack) ?? Decimal.zero;
      deliveryPack = pack.toStringAsFixed(0);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isEdited ? const Color(0xffe9f3ff) : const Color(0xffF8F8F8),
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
                if (ordersHistoryDataModel?.orderStatus != "9")
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: tr('qty_with_colon')),
                            TextSpan(
                              text: product.qty ?? '',
                              style: const TextStyle(
                                  fontSize: 15, color: appPrimaryColor),
                            )
                          ],
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                                text: tr('ordered_quantity_with_separator')),
                            TextSpan(
                              text: product.deliveredQty ?? '',
                              style: const TextStyle(
                                  fontSize: 15, color: appPrimaryColor),
                            )
                          ],
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: tr('ordered_pack_with_separator')),
                            TextSpan(
                              text: (Decimal.tryParse(
                                          product.deliveryPack ?? '') ??
                                      Decimal.zero)
                                  .toStringAsFixed(0),
                              style: const TextStyle(
                                  fontSize: 15, color: appPrimaryColor),
                            )
                          ],
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            tr('qty_with_colon') + (product.qty ?? ''),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tr('qty_with_colon'),
                              style: const TextStyle(fontSize: 11),
                            ),
                            SizedBox(
                              height: 30,
                              width: 30,
                              child: IconButton(
                                onPressed: () async {
                                  await updateProductQuantity(product, false);
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
                                double qty = double.tryParse(
                                      product.deliveredQty ?? '',
                                    ) ??
                                    0.0;
                                int? initialQuantity = (qty).ceil();
                                int? newQuantity = await showQuantityPicker(
                                  context,
                                  initialQuantity: initialQuantity,
                                );
                                if (newQuantity == null) return;
                                await updateProductQuantity(
                                  product,
                                  true,
                                  newQuantity: newQuantity,
                                );
                              },
                              child: Text(deliveredQty),
                            ),
                            const SizedBox(width: 5),
                            SizedBox(
                              height: 30,
                              width: 30,
                              child: IconButton(
                                onPressed: () async {
                                  await updateProductQuantity(product, true);
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
                            Text(
                              tr('packs_with_colon'),
                              style: const TextStyle(fontSize: 11),
                            ),
                            SizedBox(
                              height: 30,
                              width: 30,
                              child: IconButton(
                                onPressed: () async {
                                  await updateDeliveryPackQuantity(
                                      product, false);
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
                                int? newQuantity = await showQuantityPicker(
                                  context,
                                  initialQuantity: (double.tryParse(
                                              product.deliveryPack ?? '0') ??
                                          0.0)
                                      .ceil(),
                                );
                                if (newQuantity == null) return;
                                await updateDeliveryPackQuantity(
                                  product,
                                  true,
                                  newQuantity: newQuantity,
                                );
                              },
                              child: Text(deliveryPack),
                            ),
                            const SizedBox(width: 5),
                            SizedBox(
                              height: 30,
                              width: 30,
                              child: IconButton(
                                onPressed: () async {
                                  await updateDeliveryPackQuantity(
                                      product, true);
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

  Widget _orderDetailsWidget(WarehouseHistoryDataModel dataModel) {
    return Container(
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
              Text(dataModel.businessName.toString()),
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Sub Total",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                "\$${dataModel.orderedTotal ?? '0'}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: Text(tr('discount'))),
              Text("\$${dataModel.adiscount ?? ''}"),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  tr('total_amount'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                "\$${dataModel.totalamount ?? '0'}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (dataModel.orderStatus == "9")
            Column(
              children: [
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: MaterialButton(
                        color: appPrimaryColor,
                        disabledColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        height: 40,
                        onPressed: isAPIRequestInProgress
                            ? null
                            : dispatchGoodsButtonAction,
                        child: Text(
                          tr('dispatch_goods'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      child: TextButton(
                        onPressed: addProductAction,
                        child: Text(tr('add_products')),
                      ),
                    ),
                  ],
                ),
              ],
            )
        ],
      ),
    );
  }

  Future<void> addProductAction() async {
    WarehouseOrderDetailsPage.addedProduct = ValueNotifier([]);
    Map<String, dynamic> parameters = {};
    parameters["orderId"] = widget.orderId;
    parameters["isFromCart"] = false;
    await FullVendor.instance
        .pushNamed(WareHouseCreditPage.routeName, parameters: parameters);
    await updateAddedProduct();
    WarehouseOrderDetailsPage.addedProduct = null;
    refreshIndicatorKey.currentState?.show();
  }

  Future<void> updateAddedProduct() async {
    var list = WarehouseOrderDetailsPage.addedProduct?.value ?? [];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Adding ${list.length} new products"),
              const CircularProgressIndicator()
            ],
          ),
        );
      },
    );

    for (var element in list) {
      dynamic response;
      try {
        response = await Apis().editWarehouseOrderByAddingProduct(
          orderId: widget.orderId ?? '',
          product: element,
          quantity: int.tryParse(element.qty ?? '0') ?? 0,
          ordersHistoryDataModel: ordersHistoryDataModel,
        );
      } catch (e) {
        if (e is DioException) {
          if (!saveOffline) {
            saveOffline = await handlerOrderPlaceError(
              error: e,
              orderId: null,
              productID: null,
              pack: null,
              quantity: null,
            );
          }
          if (!saveOffline) continue;
          String orderId = widget.orderId ?? '';
          String productId = element.productId ?? '0';
          int quantity = int.tryParse(element.deliveredQty ?? '0') ?? 0;
          await SyncedDB.instance.insertWarehouseOrder(
            orderId: orderId,
            productId: productId,
            quantity: quantity,
            packs: 0,
          );
          await OfflineSavedDB.instance.updateOrInsert(
            orderId: orderId,
            productId: productId,
            quantity: quantity,
            pack: 0,
          );
        }
      }
      if (kDebugMode) {
        print(jsonEncode(response));
      }
    }
    if (!mounted) return;
    Navigator.pop(context);
    Fluttertoast.showToast(msg: 'Updated');
  }

  Widget _addressToShipWidget(Customer customer) {
    String deliveryAddress = '';
    if (customer.commercialAddress?.isNotEmpty ?? false) {
      deliveryAddress = customer.commercialAddress ?? '';
      deliveryAddress += ', ';
    }
    if (customer.commercialZone?.isNotEmpty ?? false) {
      deliveryAddress += customer.commercialZone ?? '';
      deliveryAddress += ', ';
    }
    if (customer.commercialCity?.isNotEmpty ?? false) {
      deliveryAddress += customer.commercialCity ?? '';
      deliveryAddress += ', ';
    }
    if (customer.commercialState?.isNotEmpty ?? false) {
      deliveryAddress += customer.commercialState ?? '';
      deliveryAddress += ', ';
    }
    if (customer.commercialCountry?.isNotEmpty ?? false) {
      deliveryAddress += customer.commercialCountry ?? '';
      deliveryAddress += ', ';
    }
    if (customer.commercialZipCode?.isNotEmpty ?? false) {
      deliveryAddress += customer.commercialZipCode ?? '';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xffF8F8F8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5),
          Text(
            customer.businessName ?? '',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, height: 1),
          ),
          Text(customer.name ?? '', style: const TextStyle(height: 1)),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: appPrimaryColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  deliveryAddress,
                  style: const TextStyle(
                    height: 1,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 10),
          Row(
            children: [
              const Icon(Icons.phone_outlined, color: appPrimaryColor),
              const SizedBox(width: 5),
              Text(
                customer.phone ?? '',
                style: const TextStyle(
                  height: 1,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 10),
          Row(
            children: [
              const Icon(Icons.email_outlined, color: appPrimaryColor),
              const SizedBox(width: 5),
              Text(
                customer.email ?? '',
                style: const TextStyle(
                  height: 1,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> updateProductQuantity(ProductList product, bool isIncrement,
      {int? newQuantity}) async {
    int quantity = (double.tryParse(product.deliveredQty ?? '0') ?? 0.0).ceil();
    if (newQuantity == null) {
      if (!isIncrement) {
        quantity--;
      } else {
        quantity++;
      }
    } else {
      quantity = newQuantity;
    }
    if (quantity < -1) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title:
              Text(tr('updating_quantity_to_arg', args: [quantity.toString()])),
          content: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
            ],
          ),
        );
      },
    );
    try {
      dynamic response = await Apis().editWarehouseOrderProductDeliverPack(
        orderId: widget.orderId ?? '',
        product: product,
        quantity: quantity.toString(),
        pack: product.deliveryPack ?? '0',
      );
      if (kDebugMode) {
        print(response);
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      await handlerOrderPlaceError(
        error: e as DioException,
        orderId: widget.orderId,
        productID: product.productId,
        pack: product.deliveryPack ?? '0',
        quantity: quantity.toString(),
      );
    }
    if (!mounted) return;
    Navigator.pop(context);
    refreshIndicatorKey.currentState?.show();
  }

  Future<void> updateDeliveryPackQuantity(ProductList product, bool isIncrement,
      {int? newQuantity}) async {
    int quantity = (double.tryParse(product.deliveryPack ?? '0') ?? 0.0).ceil();
    if (newQuantity == null) {
      if (!isIncrement) {
        quantity--;
      } else {
        quantity++;
      }
    } else {
      quantity = newQuantity;
    }
    if (quantity < -1) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(tr('updating_pack_to_arg', args: [quantity.toString()])),
          content: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
            ],
          ),
        );
      },
    );
    try {
      dynamic response = await Apis().editWarehouseOrderProductDeliverPack(
        orderId: widget.orderId ?? '',
        product: product,
        pack: quantity.toString(),
        quantity: product.deliveredQty ?? '0',
      );
      print(response);
    } catch (e) {
      print(e);
      await handlerOrderPlaceError(
        error: e as DioException,
        orderId: widget.orderId,
        productID: product.productId,
        quantity: product.deliveredQty ?? '0',
        pack: quantity.toString(),
      );
    }
    if (!mounted) return;
    Navigator.pop(context);
    refreshIndicatorKey.currentState?.show();
  }

  Future<void> dispatchGoodsButtonAction() async {
    if (isAPIRequestInProgress) return;
    if (ordersHistoryDataModel == null) return;
    isAPIRequestInProgress = true;
    setState(() {});
    OrderDispatchAPIRequestModel requestModel = OrderDispatchAPIRequestModel(
      deliveryStatus: "1",
      orderId: ordersHistoryDataModel!.orderId,
      orderStatus: "11",
      productlist: ordersHistoryDataModel!.productList?.map((e) {
        return OrderReceivedProductList(
          productId: e.productId,
          deliveredQuantity: e.deliveredQty,
          deliveredPack: e.deliveryPack,
        );
      }).toList(),
    );
    if (requestModel.productlist
            ?.where((element) => element.deliveredQuantity == "0")
            .isNotEmpty ??
        false) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr('contain_zero_warning'),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            actions: [
              MaterialButton(
                disabledColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                color: appPrimaryColor,
                textColor: Colors.white,
                onPressed: () {
                  isAPIRequestInProgress = false;
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Ok'),
              )
            ],
          );
        },
      );
      return;
    }
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
        Fluttertoast.showToast(msg: tr('order_dispatched'));
        if (!mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      if (e is DioException) {
        bool? save = await _showNoInternetDialog(context);
        if (save == null || !save) {
          isAPIRequestInProgress = false;
          setState(() {});
          return;
        } else {
          String orderId = widget.orderId ?? '';
          await OfflineSavedDB.instance
              .insertOrderStatusUpdateTrack(orderId, "D");
          await SyncedDB.instance.updateOrInsertWarehouseOrder(
              orderId: orderId, orderStatus: "11");
          Fluttertoast.showToast(msg: tr('order_dispatched'));
          if (!mounted) return;
          Navigator.pop(context);
          return;
        }
      }
      print(e);
      if (mounted) {
        context.showSnackBar(e.toString());
      } else {
        Fluttertoast.showToast(msg: e.toString());
      }
    }
    if (!mounted) return;
    isAPIRequestInProgress = false;
    setState(() {});
  }

  Future<void> loadOrderDetails() async {
    dynamic response =
        await Apis().loadWareHouseOrderDetails(orderId: widget.orderId ?? '');
    if (response['status'] != "1") {
      Fluttertoast.showToast(msg: response['error']);
      throw Exception(response['error'] ?? tr('something_went_wrong'));
    }
    response = response['order_info'];
    String orderDetailsString = jsonEncode(response);
    print(orderDetailsString);
    ordersHistoryDataModel = WarehouseHistoryDataModel.fromJson(response);
    print(jsonEncode(response));
    if (!mounted) return;
    setState(() {});
  }

  Future<void> loadData() async {
    try {
      await loadOrderDetails();
      Map<String, dynamic>? customerData =
          await SyncedDB.instance.readCustomerDetails(
        ordersHistoryDataModel?.customerId ?? '',
      );
      customerDataModel = Customer.fromJson(customerData);
      if (mounted) {
        setState(() {});
      }
      return;
    } catch (e) {
      print(e);
    }

    List<Map<String, dynamic>>? dataModel = await SyncedDB.instance
        .readWarehouseOrders(orderId: widget.orderId, isHistory: null);
    var first = dataModel.firstOrNull;
    if (first == null) return;
    ordersHistoryDataModel = WarehouseHistoryDataModel.fromJson(first);
    Map<String, dynamic>? customerData =
        await SyncedDB.instance.readCustomerDetails(
      ordersHistoryDataModel?.customerId ?? '',
    );
    customerDataModel = Customer.fromJson(customerData);
    if (!mounted) return;
    setState(() {});
  }

  Future<bool> handlerOrderPlaceError({
    required DioException error,
    String? orderId,
    String? productID,
    String? quantity,
    String? pack,
  }) async {
    if (error.type == DioExceptionType.connectionError) {
      if (!saveOffline) {
        saveOffline = await confirmSaveOfflineAndPlaceWhenNetworkAvailable(
            context: context);
      }
      if (!saveOffline) return saveOffline;
      bool isSkipPerformSaveAction = orderId == null ||
          productID == null ||
          quantity == null ||
          pack == null;
      if (isSkipPerformSaveAction) return saveOffline;
      try {
        await SyncedDB.instance.updateOrInsertProductToWareHouseOrder(
          orderId: widget.orderId ?? '',
          productId: productID,
          quantity: int.tryParse(quantity) ?? 0,
          packs: int.tryParse(pack) ?? 0,
        );
      } catch (e) {
        print(e);
      }
    }
    return saveOffline;
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
