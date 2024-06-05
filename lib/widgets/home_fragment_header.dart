import 'package:FullVendor/application/application_global_keys.dart';
import 'package:FullVendor/db/sql/cart_sql_helper.dart';
import 'package:FullVendor/screens/sync/customer_sync_page.dart';
import 'package:FullVendor/screens/sync/offline_data_for_sync.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../generated/assets.dart';

class UserNameHeaderWithSync extends StatelessWidget {
  const UserNameHeaderWithSync({
    super.key,
    required this.name,
    required this.role,
    required this.allowBack,
    this.badgeCount = 0,
    this.onBack,
    this.isUpdateAvailable = false,
    // this.onSync,
  });
  final String name;
  final String role;
  final bool allowBack;
  final int badgeCount;
  final bool isUpdateAvailable;
  final Function()? onBack;
  // final Function()? onSync;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (allowBack)
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  )
                else
                  Image.asset(Assets.assetsWhileLogoWithoutName, height: 24, width: 24),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      role,
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isUpdateAvailable)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: // onSync ??
                      () async {
                    if (badgeCount != 0) {
                      await FullVendor.instance.pushNamed(OfflineChangeSetWidget.routeName);
                    }
                    await FullVendor.instance.pushNamed(
                      SyncPage.routeName,
                      parameters: {"isForceSync": true},
                    );
                    updateCartQuantity();
                  },
                  child: Container(
                    // decoration: BoxDecoration(
                    //   color: Colors.white,
                    //   borderRadius: BorderRadius.circular(20),
                    // ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Row(
                      children: [
                        const Icon(Icons.flag, color: Colors.white, size: 18),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tr('update_available'),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          InkWell(
            radius: 16,
            splashColor: Colors.white,
            onTap: // onSync ??
                () async {
              if (badgeCount != 0) {
                await FullVendor.instance.pushNamed(OfflineChangeSetWidget.routeName);
                return;
              }
              await FullVendor.instance.pushNamed(SyncPage.routeName);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  Badge.count(
                    count: badgeCount,
                    backgroundColor: Colors.grey,
                    isLabelVisible: badgeCount > 0,
                    child: const Icon(Icons.sync, color: Colors.black, size: 18),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tr('sync'),
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
