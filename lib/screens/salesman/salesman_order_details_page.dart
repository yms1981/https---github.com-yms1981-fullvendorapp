import 'dart:convert';

import 'package:FullVendor/network/apis.dart';
import 'package:FullVendor/utils/extensions.dart';
import 'package:FullVendor/widgets/app_theme_widget.dart';
import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../application/theme.dart';
import '../../db/synced_db.dart';
import '../../model/customer_list_data_model.dart';
import '../../model/order_history_data_model.dart';
import '../../widgets/full_vendor_cache_image_loader.dart';
import '../../widgets/refresh_indicator.dart';
import '../../widgets/salesman/salesman_fragment_header_widget.dart';

class SalesmanOrderDetailsPage extends StatefulWidget {
  const SalesmanOrderDetailsPage({super.key, this.orderId});
  static const String routeName = '/salesman/order/details';
  final String? orderId;

  @override
  State<SalesmanOrderDetailsPage> createState() =>
      _SalesmanOrderDetailsPageState();
}

class _SalesmanOrderDetailsPageState extends State<SalesmanOrderDetailsPage> {
  OrderList? ordersHistoryDataModel;
  GlobalKey<RefreshIndicatorState> refreshIndicatorKey = GlobalKey();
  Customer? customerDataModel;

  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      appBar: SalesmanTopBar(
        title: tr(
          'order_details_with_order_id',
          args: [widget.orderId ?? ''],
        ),
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

  Widget _orderedProduct(OrderList dataModel) {
    return Container(
      // padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      margin: const EdgeInsets.symmetric(vertical: 4),
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(10),
      //   color: const Color(0xffF8F8F8),
      // ),
      child: Column(
        children: List.generate(dataModel.productList?.length ?? 0, (index) {
          return _productElement(dataModel.productList![index]);
        }),
      ),
    );
  }

  Widget _productElement(ProductList product) {
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
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xff000000)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FullVendorCacheImageLoader(
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
                      TextSpan(
                        text: ' x ${product.qty ?? ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const TextSpan(text: ' = '),
                      // total price
                      TextSpan(
                        text:
                            "\$${(Decimal.parse(product.salePrice ?? '0') * Decimal.parse(product.qty ?? '0')).toDecimalFormat()}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: tr('ordered_quantity_with_separator')),
                    TextSpan(
                      text: product.qty ?? '',
                      style:
                          const TextStyle(fontSize: 18, color: appPrimaryColor),
                    )
                  ]),
                  style: const TextStyle(fontSize: 15, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderDetailsWidget(OrderList dataModel) {
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
                "\$${dataModel.amount ?? '0'}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: Text(tr('total_discount'))),
              Text("\$${dataModel.discounta ?? '0'}"),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  tr('total_order_value'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                "\$${dataModel.orderedTotal ?? '0'}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
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

  Future<void> loadOrderFromNetwork() async {
    dynamic response =
        await Apis().loadSalesmanOrder(orderId: widget.orderId ?? '-1');
    if (response is Map<String, dynamic>) {
      String responseString = jsonEncode(response);
      print(responseString);
      if (response['status'] == '1') {
        ordersHistoryDataModel = OrderList.fromJson(response['order_info']);
        Map<String, dynamic>? customerData = await SyncedDB.instance
            .readCustomerDetails(ordersHistoryDataModel?.customerId ?? '');
        customerDataModel = Customer.fromJson(customerData);
        if (!mounted) return;
        setState(() {});
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['error'] ?? tr('something_went_wrong')),
            ),
          );
        }
        throw Exception(response['error'] ?? tr('something_went_wrong'));
      }
    } else {
      if (mounted) {
        context.showSnackBar(tr('response_not_in_correct_format'));
      }
      throw Exception('Response is not in correct format');
    }
  }

  Future<void> loadData() async {
    try {
      await loadOrderFromNetwork();
      return;
    } catch (e) {
      print(e);
    }
    List<Map<String, dynamic>>? dataModel =
        await SyncedDB.instance.readOrderHistoryList(
      customerId: defaultCustomerNotifier.value?.customerId ?? '',
      orderId: widget.orderId,
    );

    ordersHistoryDataModel = OrderList.fromJson(dataModel.first);

    Map<String, dynamic>? customerData = await SyncedDB.instance
        .readCustomerDetails(ordersHistoryDataModel?.customerId ?? '');
    customerDataModel = Customer.fromJson(customerData);
    if (!mounted) return;
    setState(() {});
  }
}
