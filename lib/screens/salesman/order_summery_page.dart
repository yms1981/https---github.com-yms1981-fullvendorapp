import 'package:FullVendor/application/application_global_keys.dart';
import 'package:FullVendor/application/theme.dart';
import 'package:FullVendor/db/shared_pref.dart';
import 'package:FullVendor/db/sql/cart_sql_helper.dart';
import 'package:FullVendor/model/customer_list_data_model.dart';
import 'package:FullVendor/model/login_model.dart';
import 'package:FullVendor/screens/salesman/salesman_order_details_page.dart';
import 'package:FullVendor/screens/warehouse/warehouse_order_details.dart';
import 'package:FullVendor/utils/extensions.dart';
import 'package:FullVendor/widgets/app_theme_widget.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../db/offline_saved_db.dart';
import '../../model/place_order_model.dart';
import '../../model/product_list_data_model.dart';
import '../../network/apis.dart';
import '../../widgets/dialogs/save_offline_and_place_when_online_dialog.dart';
import '../../widgets/salesman/salesman_fragment_header_widget.dart';
import '../../widgets/salesman/salesman_profile_widget.dart';

class OrderSummaryPage extends StatefulWidget {
  const OrderSummaryPage({super.key, required this.orderMode});

  static const String routeName = '/salesman/order-summary';
  final String orderMode;

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  bool isLoading = false;
  final TextEditingController _notesController =
      TextEditingController(text: FullVendorSharedPref.instance.orderComment);
  Decimal totalOrderValue = Decimal.zero;
  Decimal totalDiscount = Decimal.zero;
  Decimal totalPayableAmount = Decimal.zero;
  int totalItems = 0;

  @override
  void initState() {
    super.initState();
    cartQuantityNotifier.addListener(calculateTotal);
    defaultCustomerNotifier.addListener(calculateTotal);
    calculateTotal();
    _notesController.addListener(() {
      FullVendorSharedPref.instance.orderComment = _notesController.text;
    });
    customerUpdateHandler();
  }

  Future<void> customerUpdateHandler() async {
    isLoading = true;
    setState(() {});
    try {
      await updateCustomerDetails();
    } catch (_) {}
    isLoading = false;
    if (!mounted) return;
    setState(() {});
  }

  Future<void> updateCustomerDetails() async {
    String customerId = defaultCustomerNotifier.value?.customerId ?? '';
    dynamic response = await Apis().getCustomerDetails(customerId: customerId);
    if (response['status'] != '1') return;
    dynamic details = response['details'].first;
    Customer updatedDetails = Customer.fromJson(details);
    if (defaultCustomerNotifier.value?.customerId ==
        updatedDetails.customerId) {
      defaultCustomerNotifier.value = updatedDetails;
    }
  }

  @override
  dispose() {
    cartQuantityNotifier.removeListener(calculateTotal);
    defaultCustomerNotifier.removeListener(calculateTotal);
    super.dispose();
  }

  Future<void> calculateTotal() async {
    totalOrderValue = Decimal.zero;
    totalDiscount = Decimal.zero;
    totalPayableAmount = Decimal.zero;
    double discount =
        double.tryParse(defaultCustomerNotifier.value?.discount ?? '0') ?? 0;
    Decimal priceVariation = Decimal.parse(
        defaultCustomerNotifier.value?.percentPriceAmount ?? '0.0');
    priceVariation = priceVariation * Decimal.parse("0.01");
    bool increasePrice = defaultCustomerNotifier.value?.percentageOnPrice
            ?.toLowerCase()
            .contains("increase") ??
        true;
    List<ProductDetailsDataModel> cartItems = await getCart();
    totalItems = cartItems.length;
    for (ProductDetailsDataModel product in cartItems) {
      Decimal salePrice =
          Decimal.tryParse(product.salePrice?.replaceAll('\$', '') ?? '0') ??
              Decimal.zero;
      int quantity = await cartQuantityByProductId(product.productId ?? '');
      if (increasePrice) {
        salePrice += salePrice * priceVariation;
      } else {
        salePrice -= salePrice * priceVariation;
      }
      totalOrderValue += (salePrice * Decimal.parse("$quantity"));
      totalDiscount += salePrice *
          Decimal.parse("$quantity") *
          (Decimal.parse("$discount") * Decimal.parse("0.01"));
    }
    totalPayableAmount = totalOrderValue - totalDiscount;
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    String title = tr("order_summary");
    switch (widget.orderMode) {
      case "D":
        title = tr('order_summary');
        break;
      case "C":
        title = tr('credit_summary');
        break;
      case "I":
        title = tr('inventory_summary');
        break;
    }
    return AppThemeWidget(
      appBar: Expanded(
        child: Column(
          children: [
            SalesmanTopBar(
              title: title,
              onBackPress: () async {
                Navigator.of(context).pop();
              },
            ),
            Expanded(
              child: ListView(
                children: [
                  const SalesmanProfileWidget(),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xffF8F8F8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(tr('total_products'))),
                            Text(totalItems.toString()),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: Text(tr('total_order_value'))),
                            Text("\$${totalOrderValue.toDecimalFormat()}"),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                                child: Text(
                              "${tr('total_discount')} (${defaultCustomerNotifier.value?.discount ?? '0'}%)",
                            )),
                            Text("\$${totalDiscount.toDecimalFormat()}"),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tr('total_amount'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: appPrimaryColor,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              "\$${totalPayableAmount.toDecimalFormat()}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: appPrimaryColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(right: 15.0, left: 15, top: 15),
                    child: Text(
                      tr('shipping_address'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _addressToShipWidget(),
                  Padding(
                    padding:
                        const EdgeInsets.only(right: 15.0, left: 15, top: 15),
                    child: Text(
                      tr('additional_comments'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _notesWithOrderWidget(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      flex: 0,
      body: const SizedBox(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(
          top: 5,
          left: 10,
          right: 10,
          // bottom: context.mediaQuery.viewPadding.bottom,
        ),
        child: MaterialButton(
          color: appPrimaryColor,
          disabledColor: Colors.grey.shade600,
          onPressed: isLoading
              ? null
              : () async {
                  isLoading = true;
                  setState(() {});
                  OrderPlaceRequestBody orderPlaceRequestBody =
                      OrderPlaceRequestBody();
                  orderPlaceRequestBody.customerId =
                      defaultCustomerNotifier.value?.customerId ?? '';
                  orderPlaceRequestBody.orderComment = _notesController.text;
                  orderPlaceRequestBody.languageId = "1";
                  orderPlaceRequestBody.discountType = '2';
                  orderPlaceRequestBody.orderstatus = '15';
                  // no idea what is this
                  orderPlaceRequestBody.tipod = widget.orderMode;
                  orderPlaceRequestBody.companyId =
                      defaultCustomerNotifier.value?.companyId ?? '';
                  orderPlaceRequestBody.userId =
                      LoginDataModel.instance.info?.userId ?? '';
                  orderPlaceRequestBody.discount =
                      totalDiscount.toDecimalFormat();
                  orderPlaceRequestBody.amount =
                      totalPayableAmount.toDecimalFormat();
                  orderPlaceRequestBody.bussName =
                      defaultCustomerNotifier.value?.businessName ?? '';
                  orderPlaceRequestBody.contactName =
                      defaultCustomerNotifier.value?.name ?? '';

                  try {
                    orderPlaceRequestBody.itemList = await itemsList();
                    await placeOrder(orderPlaceRequestBody);
                  } on DioException catch (error, trace) {
                    await handlerOrderPlaceError(
                        error, trace, orderPlaceRequestBody);
                  }
                  isLoading = false;
                  if (mounted) {
                    setState(() {});
                  }
                },
          height: 50,
          minWidth: double.infinity,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  tr('place_order'),
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ),
    );
  }

  Future<void> handlerOrderPlaceError(
    DioException error,
    StackTrace trace,
    OrderPlaceRequestBody orderPlaceRequestBody,
  ) async {
    if (error.type == DioExceptionType.connectionError) {
      bool saveOffline = await confirmSaveOfflineAndPlaceWhenNetworkAvailable(
          context: context);
      if (!saveOffline && !mounted) return;
      if (saveOffline) {
        await OfflineSavedDB.instance.saveOfflineOrder(orderPlaceRequestBody);
        await clearCart();
        FullVendorSharedPref.instance.orderComment = '';
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        context.showSnackBar(tr("connection_error"));
      }
    } else {
      context.showSnackBar(tr("error_while_placing_order"));
    }
  }

  Future<void> placeOrder(OrderPlaceRequestBody orderPlaceRequestBody) async {
    // await Future.delayed(const Duration(seconds: 2));
    dynamic response = {};
    if (widget.orderMode == "D") {
      response =
          await Apis().placeOrder(orderPlaceRequestBody: orderPlaceRequestBody);
    } else if (widget.orderMode == "C") {
      response = await Apis()
          .placeCreditOrder(orderPlaceRequestBody: orderPlaceRequestBody);
    } else {
      response = {'error': 'Invalid tpod type'};
    }
    if (response['status'] == "1") {
      await clearCart();
      FullVendorSharedPref.instance.orderComment = '';
      if (!mounted) return;
      dynamic orderId = response['order_id'];
      Navigator.pop(context);
      Future.delayed(const Duration(seconds: 1), () {
        String routeName = SalesmanOrderDetailsPage.routeName;
        if (widget.orderMode == "C") {
          routeName = WarehouseOrderDetailsPage.routeName;
        }
        FullVendor.instance.pushNamed(routeName, parameters: orderId);
      });
    } else {
      if (!mounted) return;
      context.showSnackBar(response['error'] ?? tr('something_went_wrong'));
    }
  }

  Future<List<OrderPlaceList>> itemsList() async {
    List<ProductDetailsDataModel> cartItems = await getCart();
    List<OrderPlaceList> itemList = [];
    for (ProductDetailsDataModel product in cartItems) {
      OrderPlaceList orderPlaceList = OrderPlaceList();

      /// quantity is the number of items in the cart
      /// it may be negative if logged is as Warehouse
      int quantity = await cartQuantityByProductId(product.productId ?? '');

      Decimal percPrice =
          Decimal.tryParse(product.purchasePrice ?? '0') ?? Decimal.zero;
      String groupCustomer = defaultCustomerNotifier.value?.groupName ?? '';
      Decimal salePrice =
          Decimal.tryParse(product.salePrice?.replaceAll('\$', '') ?? '0') ??
              Decimal.zero;
      Decimal totalPrice = Decimal.zero;
      Decimal discount = Decimal.parse(
          defaultCustomerNotifier.value?.percentPriceAmount ?? '0.0');
      bool increasePrice = defaultCustomerNotifier.value?.percentageOnPrice
              ?.toLowerCase()
              .contains("increase") ??
          true;
      discount = discount * Decimal.parse("0.01");
      if (increasePrice) {
        totalPrice = salePrice + (salePrice * discount);
      } else {
        totalPrice = salePrice - (salePrice * discount);
      }

      orderPlaceList.productId = product.productId;
      orderPlaceList.qty = quantity.toString();
      orderPlaceList.percprice = percPrice.toDouble();
      orderPlaceList.impprice = 0.0;
      orderPlaceList.groupcustomer = groupCustomer;

      orderPlaceList.tipolista =
          defaultCustomerNotifier.value?.percentageOnPrice ?? '';
      orderPlaceList.salesp = totalPrice.toDouble();
      orderPlaceList.totalprice = totalPrice.toDouble() /* * quantity*/;

      orderPlaceList.discount = '0';
      orderPlaceList.discountType = '1';
      orderPlaceList.comment =
          await notesByProductId(product.productId ?? '-1');
      itemList.add(orderPlaceList);
    }
    return itemList;
  }

  Widget _addressToShipWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xffF8F8F8),
      ),
      child: ValueListenableBuilder(
        valueListenable: defaultCustomerNotifier,
        builder: (context, value, child) {
          String deliveryAddress = '';
          if (value?.commercialAddress?.isNotEmpty ?? false) {
            deliveryAddress = value?.commercialAddress ?? '';
            deliveryAddress += ', ';
          }
          if (value?.commercialZone?.isNotEmpty ?? false) {
            deliveryAddress += value?.commercialZone ?? '';
            deliveryAddress += ', ';
          }
          if (value?.commercialCity?.isNotEmpty ?? false) {
            deliveryAddress += value?.commercialCity ?? '';
            deliveryAddress += ', ';
          }
          if (value?.commercialState?.isNotEmpty ?? false) {
            deliveryAddress += value?.commercialState ?? '';
            deliveryAddress += ', ';
          }
          if (value?.commercialCountry?.isNotEmpty ?? false) {
            deliveryAddress += value?.commercialCountry ?? '';
            deliveryAddress += ', ';
          }
          if (value?.commercialZipCode?.isNotEmpty ?? false) {
            deliveryAddress += value?.commercialZipCode ?? '';
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Text(
                value?.businessName ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, height: 1),
              ),
              Text(value?.name ?? '', style: const TextStyle(height: 1)),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      color: appPrimaryColor),
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
                    value?.phone ?? '',
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
                    value?.email ?? '',
                    style: const TextStyle(
                      height: 1,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _notesWithOrderWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xffF8F8F8),
      ),
      child: TextField(
        controller: _notesController,
        textInputAction: TextInputAction.done,
        keyboardType: TextInputType.multiline,
        maxLines: 5,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: tr('note_optional'),
        ),
      ),
    );
  }
}
