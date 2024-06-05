import 'dart:async';

import 'package:FullVendor/application/application_global_keys.dart';
import 'package:FullVendor/db/sql/cart_sql_helper.dart';
import 'package:FullVendor/screens/warehouse/warehouse_credit_note.dart';
import 'package:FullVendor/screens/warehouse/warehouse_history_page.dart';
import 'package:FullVendor/screens/warehouse/warehouse_inventory_control_page.dart';
import 'package:FullVendor/utils/extensions.dart';
import 'package:FullVendor/widgets/app_theme_widget.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../db/offline_saved_db.dart';
import '../../generated/assets.dart';
import '../../model/database_version_check_model.dart';
import '../../model/login_model.dart';
import '../../widgets/dialogs/no_customer_selected_dialog.dart';
import '../../widgets/home_fragment_header.dart';
import '../sync/customer_sync_page.dart';

class WarehouseHomeFragment extends StatefulWidget {
  const WarehouseHomeFragment({super.key});

  @override
  State<WarehouseHomeFragment> createState() => _SalesmanHomeFragmentState();
}

class _SalesmanHomeFragmentState extends State<WarehouseHomeFragment>
    with RouteAware {
  int offlineChangeSetCount = 0;
  StreamSubscription<List<ConnectivityResult>>? subscription;
  bool isNetworkAvailableActionInProgress = false;

  @override
  void initState() {
    super.initState();

    Connectivity().checkConnectivity().then(connectionObserver);
    subscription =
        Connectivity().onConnectivityChanged.listen(connectionObserver);
    loadOfflineOrderCount();
    defaultCustomerNotifier.addListener(loadOfflineOrderCount);
    cartQuantityNotifier.addListener(loadOfflineOrderCount);
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
    await loadOfflineOrderCount();
    if (!mounted) return;
    if (offlineChangeSetCount > 0) {
      await showOfflineDataReadyForSync(context);
    }
    VersionCheckModel updateCheckModel =
        await isDBUpdateAvailable(allowMicroUpdate: true);
    if (!mounted) return;
    if (updateCheckModel.isUpdateAvailable) {
      bool isUpdate = await showUpdateDialog(
        versionCheckModel: updateCheckModel,
        context: context,
      );
      if (isUpdate) {
        await FullVendor.instance
            .pushNamed(SyncPage.routeName, parameters: {"isForceSync": true});
        await loadOfflineOrderCount();
      }
    }
  }

  Future<void> loadOfflineOrderCount() async {
    offlineChangeSetCount =
        await OfflineSavedDB.instance.offlineChangeSetCount();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    subscription?.cancel();
    cartQuantityNotifier.removeListener(loadOfflineOrderCount);
    defaultCustomerNotifier.removeListener(loadOfflineOrderCount);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      appBar: UserNameHeaderWithSync(
        name: LoginDataModel.instance.info?.firstName ?? "",
        role: LoginDataModel.instance.info?.companyName ?? "",
        allowBack: false,
        badgeCount: offlineChangeSetCount,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Wrap(
            alignment: WrapAlignment.start,
            spacing: 10,
            runSpacing: 10,
            children: [
              optionWidget(
                  title: tr('order_received'),
                  iconPath: Assets.iconOrders,
                  onTap: () async {
                    await FullVendor.instance.pushNamed(
                      WareHouseOrderHistoryPage.routeName,
                      parameters: false,
                    );
                    if (!mounted) return;
                    setState(() {});
                    await loadOfflineOrderCount();
                  }),
              optionWidget(
                title: tr('order_history_2_lines'),
                iconPath: Assets.iconHistory,
                onTap: () async {
                  await FullVendor.instance.pushNamed(
                    WareHouseOrderHistoryPage.routeName,
                    parameters: true,
                  );
                  if (!mounted) return;
                  setState(() {});
                  await loadOfflineOrderCount();
                },
              ),
              optionWidget(
                title: tr('credit_notes_2_lines'),
                iconPath: Assets.iconCredit,
                onTap: () async {
                  bool isSelected = await checkIsCustomerSelected(context);
                  if (!isSelected) return;
                  await FullVendor.instance
                      .pushNamed(WareHouseCreditPage.routeName);
                  await loadOfflineOrderCount();
                },
              ),
              optionWidget(
                title: tr('inventory_control'),
                iconPath: Assets.iconInventroy,
                onTap: () async {
                  await FullVendor.instance
                      .pushNamed(WareHouseInventoryPage.routeName);
                  await loadOfflineOrderCount();
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
            const SizedBox(height: 15),
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
