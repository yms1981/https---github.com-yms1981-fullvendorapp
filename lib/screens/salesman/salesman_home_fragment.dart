import 'dart:async';

import 'package:FullVendor/application/application_global_keys.dart';
import 'package:FullVendor/screens/salesman/customer_selection_fragment.dart';
import 'package:FullVendor/screens/salesman/salesman_category_page.dart';
import 'package:FullVendor/screens/salesman/salesman_history_page.dart';
import 'package:FullVendor/screens/salesman/salesman_product_page.dart';
import 'package:FullVendor/utils/extensions.dart';
import 'package:FullVendor/widgets/app_theme_widget.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../db/offline_saved_db.dart';
import '../../db/sql/cart_sql_helper.dart';
import '../../generated/assets.dart';
import '../../model/database_version_check_model.dart';
import '../../model/login_model.dart';
import '../../widgets/dialogs/no_customer_selected_dialog.dart';
import '../../widgets/home_fragment_header.dart';
import '../../widgets/selected_customer_widget.dart';
import '../sync/customer_sync_page.dart';

class SalesmanHomeFragment extends StatefulWidget {
  const SalesmanHomeFragment({super.key});

  @override
  State<SalesmanHomeFragment> createState() => _SalesmanHomeFragmentState();
}

class _SalesmanHomeFragmentState extends State<SalesmanHomeFragment> {
  LoginDataModel? loginDataModel;
  int offlineOderCount = 0;
  StreamSubscription<List<ConnectivityResult>>? subscription;
  bool isNetworkAvailableActionInProgress = false;
  bool isUpdateAvailable = false;

  @override
  void initState() {
    super.initState();
    cartQuantityNotifier.addListener(customerAndQuantityObserver);
    defaultCustomerNotifier.addListener(customerAndQuantityObserver);
    loadOfflineOrderCount();
    Connectivity().checkConnectivity().then(connectionObserver);
    subscription = Connectivity().onConnectivityChanged.listen(connectionObserver);
  }

  Future<void> connectionObserver(List<ConnectivityResult> result) async {
    if (result.firstOrNull == ConnectivityResult.none) {
      return;
    }
    if (isNetworkAvailableActionInProgress) {
      return;
    }
    isNetworkAvailableActionInProgress = true;
    Future.delayed(const Duration(seconds: 5), () {
      isNetworkAvailableActionInProgress = false;
    });
    if (offlineOderCount > 0) {
      await showOfflineDataReadyForSync(context);
    }
    VersionCheckModel updateCheckModel = await isDBUpdateAvailable(allowMicroUpdate: true);
    if (!mounted) return;
    isUpdateAvailable = updateCheckModel.isUpdateAvailable;
    setState(() {});
    // if (updateCheckModel.isUpdateAvailable) {
    //   bool isUpdate = await showUpdateDialog(
    //     versionCheckModel: updateCheckModel,
    //     context: context,
    //   );
    //   if (isUpdate) {
    //     await FullVendor.instance
    //         .pushNamed(SyncPage.routeName, parameters: {"isForceSync": true});
    //     await customerAndQuantityObserver();
    //   }
    // }
  }

  Future<void> customerAndQuantityObserver() async {
    if (!mounted) return;
    loadOfflineOrderCount();
    setState(() {});
  }

  Future<void> loadOfflineOrderCount() async {
    offlineOderCount = await OfflineSavedDB.instance.offlineChangeSetCount();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    subscription?.cancel();
    cartQuantityNotifier.removeListener(customerAndQuantityObserver);
    defaultCustomerNotifier.removeListener(customerAndQuantityObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      appBar: Column(
        children: [
          UserNameHeaderWithSync(
            name: LoginDataModel.instance.info?.firstName ?? "",
            role: LoginDataModel.instance.info?.companyName ?? "",
            allowBack: false,
            onBack: null,
            badgeCount: offlineOderCount,
            isUpdateAvailable: isUpdateAvailable,
            // onSync: () async {
            //   Map<String, dynamic> parameters = {
            //     "isForceSync": isUpdateAvailable
            //   };
            //   await FullVendor.instance
            //       .pushNamed(SyncPage.routeName, parameters: parameters);
            //   await customerAndQuantityObserver();
            // },
          ),
          const DefaultSelectedCustomerWidget(),
        ],
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              optionWidget(
                  title: tr('customers'),
                  iconPath: Assets.iconCustomers,
                  onTap: () async {
                    dynamic response =
                        await FullVendor.instance.pushNamed(CustomerSelectionFragment.routeName);
                    if (response != null) {
                      defaultCustomerNotifier.value = response;
                    }
                    await customerAndQuantityObserver();
                  }),
              optionWidget(
                title: tr('browse_categories'),
                iconPath: Assets.iconCategory,
                onTap: () async {
                  bool isSelected = await checkIsCustomerSelected(context);
                  if (!isSelected) return;
                  await FullVendor.instance.pushNamed(SalesmanCategorySelectionPage.routeName);
                  await customerAndQuantityObserver();
                },
              ),
              optionWidget(
                title: tr('browse_products'),
                iconPath: Assets.iconProducts,
                onTap: () async {
                  bool isSelected = await checkIsCustomerSelected(context);
                  if (!isSelected) return;
                  await FullVendor.instance.pushNamed(SalesmanProductPage.routeName);
                  await customerAndQuantityObserver();
                },
              ),
              optionWidget(
                title: tr('order_history_2_lines'),
                iconPath: Assets.iconHistory,
                onTap: () async {
                  bool isSelected = await checkIsCustomerSelected(context);
                  if (!isSelected) return;
                  await FullVendor.instance.pushNamed(SalesmanHistoryPage.routeName);
                  await customerAndQuantityObserver();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget optionWidget({
    required String title,
    required String iconPath,
    Function()? onTap,
  }) {
    double width = context.mediaQuery.size.width;
    if (width < 400) {
      width = (width / 2) * 0.8;
    } else {
      width = 160;
    }
    return InkWell(
      onTap: onTap,
      radius: 10,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(10),
        ),
        constraints: BoxConstraints(minHeight: width, minWidth: width),
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            SizedBox(height: 50, width: 60, child: Image.asset(iconPath)),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
      ),
    );
  }
}
