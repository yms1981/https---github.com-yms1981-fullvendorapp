import 'package:FullVendor/screens/warehouse/warehouse_credit_note.dart';
import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../application/application_global_keys.dart';
import '../../application/theme.dart';
import '../../db/sql/cart_sql_helper.dart';
import '../../model/customer_list_data_model.dart';
import '../../model/product_list_data_model.dart';
import '../../network/apis.dart';
import '../../utils/extensions.dart';
import '../../widgets/app_theme_widget.dart';
import '../../widgets/dialogs/confirm_discard.dart';
import '../../widgets/products/product_view.dart';
import '../../widgets/salesman/salesman_fragment_header_widget.dart';
import '../../widgets/salesman/salesman_profile_widget.dart';
import '../salesman/order_summery_page.dart';

class WarehouseCartPage extends StatefulWidget {
  const WarehouseCartPage({super.key});
  static const String routeName = '/warehouse/cart';

  @override
  State<WarehouseCartPage> createState() => _WarehouseCartPageState();
}

class _WarehouseCartPageState extends State<WarehouseCartPage> {
  bool isLoading = false;
  List<ProductDetailsDataModel> cartItems = [];
  Decimal totalOrderValue = Decimal.zero;
  Decimal totalDiscount = Decimal.zero;
  Map<int, GlobalKey<ProductListElementState>> childKeys = {};

  @override
  void initState() {
    super.initState();
    cartQuantityNotifier.addListener(cartCalculationRefresh);
    defaultCustomerNotifier.addListener(cartCalculationRefresh);
    cartCalculationRefresh();
    customerUpdateHandler();
  }

  @override
  void dispose() {
    cartQuantityNotifier.removeListener(cartCalculationRefresh);
    defaultCustomerNotifier.removeListener(cartCalculationRefresh);
    super.dispose();
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

  Future<void> cartCalculationRefresh() async {
    if (cartQuantityNotifier.value == 0) {
      if (!mounted) return;
      try {
        NavigatorState navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        }
      } catch (e) {
        print(e);
      }
      return;
    }
    totalOrderValue = Decimal.zero;
    totalDiscount = Decimal.zero;
    Decimal discount =
        Decimal.tryParse(defaultCustomerNotifier.value?.discount ?? '0') ??
            Decimal.zero;
    Decimal priceVariation = Decimal.parse(
        defaultCustomerNotifier.value?.percentPriceAmount ?? '0.0');
    priceVariation = priceVariation * Decimal.parse("0.01");
    bool increasePrice = defaultCustomerNotifier.value?.percentageOnPrice
            ?.toLowerCase()
            .contains("increase") ??
        true;
    cartItems = await getCart();
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
      totalOrderValue += (salePrice * Decimal.parse(quantity.toString()));
      totalDiscount += salePrice *
          Decimal.parse(quantity.toString()) *
          (discount * Decimal.parse("0.01"));
    }
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      elevation: 2,
      flex: 0,
      appBar: Expanded(
        flex: 1,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SalesmanTopBar(
                    title: tr('cart'),
                    onBackPress: () async {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                MaterialButton(
                  onPressed: () async {
                    await FullVendor.instance.pushNamed(
                      WareHouseCreditPage.routeName,
                      parameters: {'isFromCart': true},
                    );
                    cartItems = await getCart();
                    childKeys.forEach((key, value) {
                      value.currentState?.refreshQuantity();
                    });
                    if (!mounted) return;
                    setState(() {});
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 1,
                  color: const Color(0xFFFCAEAE),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, color: appPrimaryColor),
                      const SizedBox(width: 5),
                      Text(
                        tr('add_product_uppercase'),
                        style: const TextStyle(
                          color: appPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  const SalesmanProfileWidget(),
                  for (int i = 0; i < cartItems.length; i++)
                    ProductListElement(
                      key: childKeys[i] ??=
                          GlobalKey<ProductListElementState>(),
                      productDetailsDataModel: cartItems[i],
                      allowDelete: true,
                      onAddToCart: () {
                        getCart().then(
                          (value) {
                            cartItems = value;
                            setState(() {});
                            if (cartItems.isEmpty) {
                              Navigator.of(context).pop();
                            }
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: const SizedBox(),
      bottomNavigationBar: Container(
        padding:
            const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Text(tr('total_order_value'))),
                Text("\$$totalOrderValue"),
              ],
            ),
            Row(
              children: [
                Expanded(
                    child: Text(
                  "${tr('total_discount')} (${defaultCustomerNotifier.value?.discount ?? '0'}%)",
                )),
                Text(
                  "\$${(totalDiscount)}",
                  style: const TextStyle(color: Color(0xFF503E9B)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr('total_amount'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: appPrimaryColor,
                    ),
                  ),
                ),
                Text(
                  "\$${(totalOrderValue - totalDiscount)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: appPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: MaterialButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: Colors.black,
                    height: 50,
                    textColor: Colors.white,
                    onPressed: () async {
                      bool isDiscard = await confirmCartDiscard(context);
                      if (!isDiscard) return;
                      await clearCart();
                      if (!mounted) return;
                      Navigator.of(context).pop();
                    },
                    child: Text(tr('discard')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MaterialButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: appPrimaryColor,
                    height: 50,
                    textColor: Colors.white,
                    disabledColor: Colors.grey.shade600,
                    onPressed: isLoading
                        ? null
                        : () async {
                            await FullVendor.instance.pushNamed(
                              OrderSummaryPage.routeName,
                              parameters: 'C',
                            );
                            cartItems = await getCart();
                            if (!mounted) return;
                            setState(() {});
                          },
                    child: Text(tr('order_summary')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
