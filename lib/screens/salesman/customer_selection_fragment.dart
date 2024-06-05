import 'dart:convert';

import 'package:FullVendor/application/application_global_keys.dart';
import 'package:FullVendor/db/sql/cart_sql_helper.dart';
import 'package:FullVendor/network/apis.dart';
import 'package:FullVendor/utils/extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../application/theme.dart';
import '../../db/shared_pref.dart';
import '../../db/synced_db.dart';
import '../../model/customer_list_data_model.dart';
import '../../widgets/app_theme_widget.dart';
import '../../widgets/dialogs/confirm_discard.dart';
import '../../widgets/refresh_indicator.dart';
import '../../widgets/salesman/salesman_fragment_header_widget.dart';
import '../../widgets/salesman/salesman_profile_widget.dart';
import 'add_customer_page.dart';

class CustomerSelectionFragment extends StatefulWidget {
  const CustomerSelectionFragment({super.key});
  static const String routeName = '/salesman/customer-selection';

  @override
  State<CustomerSelectionFragment> createState() =>
      _CustomerSelectionFragmentState();
}

class _CustomerSelectionFragmentState extends State<CustomerSelectionFragment> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  CustomerListDataModel? _customerListDataModel;
  String? _searchText;
  bool sortAscending = true;
  String? sortColumn;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text.trim().isEmpty) {
        _searchText = null;
        setState(() {});
        return;
      }
      _searchText = _searchController.text.trim();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      appBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SalesmanTopBar(
            title: tr('customer_selection'),
            onBackPress: () {
              Navigator.pop(context);
            },
          ),
          SalesmanProfileWidget(onEditPress: () async {}),
        ],
      ),
      body: FullVendorRefreshIndicator(
        onRefresh: loadCustomerListFrom,
        refreshIndicatorKey: _refreshIndicatorKey,
        child: Padding(
          padding: const EdgeInsets.only(top: 16, left: 13, right: 13),
          child: Column(
            children: [
              titleRow(),
              const SizedBox(height: 6),
              searchAndFilterRow(),
              Expanded(
                  child: CustomScrollView(
                slivers: [
                  SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisExtent: 105,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      return customerElement(context, index);
                    },
                    itemCount: _customerListDataModel?.list
                            ?.where((element) {
                              return filterByQuery(element);
                            })
                            .toList()
                            .length ??
                        0,
                  )
                ],
              )),
              // Expanded(
              //   child: ListView.builder(
              //     padding: const EdgeInsets.only(top: 8),
              //     itemCount:,
              //     itemBuilder: (context, index) {
              //
              //     },
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget titleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          tr('customers'),
          style: context.appTextTheme.titleMedium?.copyWith(
            color: appPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: appPrimaryLightColor,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: InkWell(
            splashColor: appPrimaryColor,
            onTap: () async {
              await FullVendor.instance.pushNamed(AddCustomerPage.routeName);
              _refreshIndicatorKey.currentState?.show();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: appPrimaryColor),
                SizedBox(width: 4),
                Text(
                  'ADD',
                  style: TextStyle(color: appPrimaryColor, fontSize: 11),
                ),
                SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget searchAndFilterRow() {
    return Row(
      children: [
        Expanded(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search',
                border: InputBorder.none,
                hintStyle: TextStyle(color: appSecondaryColor, fontSize: 12),
                prefixIcon:
                    Icon(Icons.search, color: appSecondaryColor, size: 16),
                suffixIcon: SizedBox(width: 0),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          surfaceTintColor: appPrimaryLightColor,
          elevation: 2,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: SizedBox(
            child: Row(
              children: [
                sortByOption(
                  icon: const Icon(
                    CupertinoIcons.arrow_up_arrow_down,
                    size: 16,
                    color: Colors.black,
                  ),
                  onSelected: (value) {
                    sortAscending = value;
                    loadCustomerListFromDB();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget sortByOption({
    required PopupMenuItemSelected<bool> onSelected,
    String? title,
    Widget? icon,
  }) {
    return PopupMenuButton<bool>(
      onSelected: (value) {
        onSelected(value);
      },
      icon: icon,
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            value: true,
            child: Text(tr('ascending')),
          ),
          PopupMenuItem(
            value: false,
            child: Text(tr('descending')),
          ),
        ];
      },
      child: title != null
          ? Row(
              children: [
                Text(
                  title,
                  style: context.appTextTheme.bodyMedium?.copyWith(
                    color: appSecondaryColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down,
                  color: appSecondaryColor,
                  size: 16,
                ),
              ],
            )
          : null,
    );
  }

  Widget customerElement(
    BuildContext context,
    int index, {
    Color bgColor = const Color(0xFFF8F8F8),
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: bgColor,
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: InkWell(
        radius: 8,
        onTap: () async {
          Customer? customer = _customerListDataModel?.list?.where((element) {
            return filterByQuery(element);
          }).toList()[index];
          if (cartQuantityNotifier.value != 0) {
            bool isDiscard = await confirmCartDiscard(context,
                message: tr('confirm_cart_discard'));
            if (!isDiscard) return;
            await clearCart();
          }
          if (!mounted) return;
          Navigator.pop(context, customer);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: customerDetailsElement(context, index)),
            const Icon(
              Icons.arrow_forward_ios,
              color: appSecondaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget customerDetailsElement(BuildContext context, int index) {
    Customer? customer = _customerListDataModel?.list?.where((element) {
      return filterByQuery(element);
    }).toList()[index];
    if (customer == null) return const SizedBox();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFE5E5E5), width: 1),
              ),
              elevation: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  CupertinoIcons.person_alt_circle_fill,
                  color: appPrimaryColor,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name ?? '',
                    style: context.appTextTheme.titleMedium?.copyWith(
                      color: appPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    customer.businessName ?? '',
                    style: context.appTextTheme.bodyMedium?.copyWith(
                      color: appSecondaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        // const SizedBox(height: 8),
        if ((customer.commercialAddress ?? '').isNotEmpty)
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Color(0xFFC8C8C8),
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  customer.commercialAddress ?? '',
                  style: context.appTextTheme.bodyMedium?.copyWith(
                    color: appSecondaryColor,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }

  bool filterByQuery(Customer element) {
    if (_searchText == null) return true;
    String searchFor = _searchText!.toLowerCase();
    String name = element.name?.toLowerCase() ?? '';
    String businessName = element.businessName?.toLowerCase() ?? '';
    String commercialAddress = element.commercialAddress?.toLowerCase() ?? '';
    return name.contains(searchFor) ||
        businessName.contains(searchFor) ||
        commercialAddress.contains(searchFor);
  }

  Future<void> loadCustomerListFromDB() async {
    List<Map<String, dynamic>> savedCustomers =
        await SyncedDB.instance.readCustomerList(
      order: sortAscending ? 'ASC' : 'DESC',
      sort: sortColumn ?? 'name',
      search: _searchText,
      showAll: FullVendorSharedPref.instance.userType == "2",
    );
    // List<Map<String, dynamic>> savedCustomers = await loadSavedCustomers(
    //   sortAscending: sortAscending,
    // );
    Map<String, dynamic> savedCustomersMap = {};
    savedCustomersMap['list'] = savedCustomers;

    _customerListDataModel = CustomerListDataModel.fromJson(savedCustomersMap);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> loadCustomerListFrom() async {
    FullVendor.instance.scaffoldMessengerKey.currentState
        ?.hideCurrentSnackBar();
    try {
      bool isWarehouse = FullVendorSharedPref.instance.userType == "2";
      dynamic response = await Apis().getCustomerList(isWarehouse: isWarehouse);
      print(jsonEncode(response));
      if (!mounted) return;
      CustomerListDataModel customerListDataModel =
          CustomerListDataModel.fromJson(response);
      if (customerListDataModel.list?.isEmpty ?? true) {
        throw Exception("No customers found");
      } else {
        _customerListDataModel = customerListDataModel;
        if (!mounted) return;
        setState(() {});
        return;
      }
    } catch (_) {}
    try {
      await loadCustomerListFromDB();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      if (!mounted) return;
      FullVendor.instance.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            tr('something_went_wrong_refreshing'),
            style: context.appTextTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          backgroundColor: appPrimaryColor,
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      try {
        await SyncedDB.instance.downloadDB();
      } catch (e) {
        print(e);
      }
      if (!mounted) return;
      await loadCustomerListFrom();
    }
  }
}
