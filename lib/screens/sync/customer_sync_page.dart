import 'package:FullVendor/application/application_global_keys.dart';
import 'package:FullVendor/application/theme.dart';
import 'package:FullVendor/generated/assets.dart';
import 'package:FullVendor/model/customer_list_data_model.dart';
import 'package:FullVendor/screens/sync/offline_data_for_sync.dart';
import 'package:FullVendor/widgets/app_theme_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../db/offline_saved_db.dart';
import '../../db/synced_db.dart';
import '../../model/database_version_check_model.dart';
import '../../utils/extensions.dart';

enum SyncStatus { notStarted, inProgress, completed, failed }

SyncStatus syncStatus = SyncStatus.notStarted;

class SyncPage extends StatefulWidget {
  const SyncPage({super.key, required this.isForceSync});
  final bool isForceSync;

  static const String routeName = '/sync';

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool isSyncInProgress = false;
  String lastDataBaseVersion = '';
  String updatedOn = '';
  bool isAPIInProgress = false;
  DatabaseVersionCheckModel? latestVersionInfo;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    FullVendor.instance.downloadProgress.addListener(isCanPop);
    getDBVersion();
  }

  @override
  void dispose() {
    _controller.dispose();
    FullVendor.instance.downloadProgress.removeListener(isCanPop);
    super.dispose();
  }

  Future<void> getDBVersion() async {
    try {
      Map<String, dynamic> value = await SyncedDB.instance.getSyncInfo();
      lastDataBaseVersion = value['version']?.toString() ?? '';
      updatedOn = value['fecha']?.toString() ?? '';
    } catch (e) {
      await SyncedDB.instance.downloadDB();
      return;
    }
    if (!mounted) return;
    setState(() {});
    checkVersion();
  }

  Future<void> startDownload({isMicroUpdate = false}) async {
    syncStatus = SyncStatus.inProgress;
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    try {
      if (isMicroUpdate) {
        await SyncedDB.instance.deleteDatabase();
        await SyncedDB.instance.downloadDB();
        //await SyncedDB.instance.startMicroUpdate();
      } else {
        await SyncedDB.instance.deleteDatabase();
        await SyncedDB.instance.downloadDB();
        //also apply minor patch to update
        //await SyncedDB.instance.startMicroUpdate();
      }
      syncStatus = SyncStatus.completed;
      if (!mounted) return;
      var navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      syncStatus = SyncStatus.failed;
    }
    if (!mounted) return;
    setState(() {});
    if (syncStatus != SyncStatus.completed) return;
    Customer? customer = defaultCustomerNotifier.value;
    if (customer == null) return;
    String customerID = customer.customerId ?? '';
    dynamic updatedCustomer =
        await SyncedDB.instance.readCustomerDetails(customerID);
    if (updatedCustomer == null) return;
    updatedCustomer = Customer.fromJson(updatedCustomer);
    defaultCustomerNotifier.value = updatedCustomer;
  }

  Future<void> startFullDownload({isMicroUpdate = false}) async {
    syncStatus = SyncStatus.inProgress;
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    try {
      if (isMicroUpdate) {
        await SyncedDB.instance.deleteDatabase();
        await SyncedDB.instance.downloadDB();
        //await SyncedDB.instance.startMicroUpdate();
      } else {
        await SyncedDB.instance.deleteDatabase();
        await SyncedDB.instance.downloadDB();
        //also apply minor patch to update
        //await SyncedDB.instance.startMicroUpdate();
      }
      syncStatus = SyncStatus.completed;
      if (!mounted) return;
      var navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      syncStatus = SyncStatus.failed;
    }
    if (!mounted) return;
    setState(() {});
    if (syncStatus != SyncStatus.completed) return;
    Customer? customer = defaultCustomerNotifier.value;
    if (customer == null) return;
    String customerID = customer.customerId ?? '';
    dynamic updatedCustomer =
        await SyncedDB.instance.readCustomerDetails(customerID);
    if (updatedCustomer == null) return;
    updatedCustomer = Customer.fromJson(updatedCustomer);
    defaultCustomerNotifier.value = updatedCustomer;
  }

  Future<bool> isCanPop() async {
    isSyncInProgress = FullVendor.instance.downloadProgress.value != 0.0 &&
        FullVendor.instance.downloadProgress.value != 100.0;
    if (mounted) {
      setState(() {});
    }
    return isSyncInProgress;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isSyncInProgress,
      onPopInvoked: (didPop) {
        if (didPop) {
          FullVendor.instance.downloadProgress.removeListener(isCanPop);
        }
      },
      child: AppThemeWidget(
        appBar: Row(
          children: [
            IconButton(
              onPressed: () async {
                if (isSyncInProgress) {
                  return;
                }
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const Expanded(
              child: Text(
                'Sync',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            if (lastDataBaseVersion.isNotEmpty)
              IconButton(
                onPressed: () {
                  checkVersion(isFromDrawer: true);
                },
                icon: const Icon(Icons.sync, color: Colors.white),
              ),
          ],
        ),
        bottomNavigationBar: _bottomNote(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _controller,
                child: Image.asset(Assets.imagesSyncProgress,
                    width: 100.0, height: 100.0),
              ),
              ValueListenableBuilder(
                valueListenable: FullVendor.instance.downloadProgress,
                builder: (context, value, child) {
                  return ValueListenableBuilder(
                    valueListenable: FullVendor.instance.dbUpdateLogMessage,
                    builder: (context, value, child) {
                      return _progressTextAndActions();
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressTextAndActions() {
    double progressValue = FullVendor.instance.downloadProgress.value;
    String dbUpdateMessage = FullVendor.instance.dbUpdateLogMessage.value;
    String syncMessage = '';
    if (syncStatus == SyncStatus.inProgress) {
      syncMessage = tr('downloading');
    } else if (syncStatus == SyncStatus.failed) {
      syncMessage = tr('download_failed');
    } else {
      syncMessage = tr('downloaded');
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: syncMessage,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: '${progressValue.toStringWithoutRounding(2)}%',
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: appPrimaryColor,
                ),
              ),
            ],
          ),
        ),
        Text(
          dbUpdateMessage,
          style: const TextStyle(fontSize: 14.0, color: Colors.black),
        ),
        if (progressValue >= 100 || syncStatus == SyncStatus.failed)
          MaterialButton(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            color: appPrimaryColor,
            onPressed: () async {
              if (syncStatus == SyncStatus.completed) {
                FullVendor.instance.scaffoldMessengerKey.currentState
                    ?.hideCurrentSnackBar();
                Navigator.of(context).pop();
              } else {
                await startDownload();
              }
            },
            child: Text(
              syncStatus == SyncStatus.completed ? tr('done') : tr('done'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _bottomNote() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: (lastDataBaseVersion.isNotEmpty || updatedOn.isNotEmpty)
          ? [
              const SizedBox(height: 10.0),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: "${tr('database_version')}: "),
                    TextSpan(
                      text: lastDataBaseVersion,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' | '),
                    TextSpan(text: "${tr('last_updated_on')}: "),
                    TextSpan(
                      text: updatedOn,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                  style: const TextStyle(fontSize: 12.0, color: Colors.black),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10.0),
            ]
          : [],
    );
  }

  Future<void> checkVersion({bool isFromDrawer = false}) async {
    if (isAPIInProgress) {
      return;
    }
    isAPIInProgress = true;
    if (!mounted) return;
    setState(() {});
    VersionCheckModel versionCheckModel =
        await isDBUpdateAvailable(allowMicroUpdate: true);
    isAPIInProgress = false;
    if (!mounted) return;
    setState(() {});
    if (versionCheckModel.isUpdateAvailable) {
      bool isMicro = versionCheckModel.isMicroUpdateAvailable;
      if (widget.isForceSync) {
        await startDownload(isMicroUpdate: isMicro);
      } else {
        /*await showUpdateDialog(
          versionCheckModel: versionCheckModel,
          context: context,
          onDownloadStart: startDownload,
        );*/
        await startFullDownload();
      }
    } else {
      bool? force = await databaseIsUpToDateDialog(
        lastDataBaseVersion,
        updatedOn,
        context,
      );
      if (force == true) {
        await startDownload(isMicroUpdate: true);
      } else {
        if (!mounted) return;
        Navigator.of(context).pop();
      }
    }
  }
}

/// Function to show database is up to date
/// [context] is the context of the screen
/// [lastDataBaseVersion] is the last database version
/// [updatedOn] is the last updated date
/// [latestVersionInfo] is the latest version info
Future<bool?> databaseIsUpToDateDialog(
  String lastDataBaseVersion,
  String updatedOn,
  BuildContext context,
) async {
  return await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(tr('database_up_to_date')),
        content: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${tr('database_version')}: '),
              TextSpan(
                text: lastDataBaseVersion,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' | '),
              TextSpan(text: '${tr('last_updated_on')}: '),
              TextSpan(
                text: updatedOn,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
              },
              child: Text(tr('force_update'))),
          MaterialButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            color: appPrimaryColor,
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(tr('ok')),
          ),
        ],
      );
    },
  );
}

/// Function to show update dialog
/// [versionCheckModel] is the model of the latest version
/// [context] is the context of the screen
///
Future<bool> showUpdateDialog({
  VersionCheckModel? versionCheckModel,
  required BuildContext context,
  VoidCallback? onDownloadStart,
}) async {
  bool? update = await showDialog<bool?>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(tr('update_available')),
        content: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: tr('a_new_version')),
              TextSpan(
                text: versionCheckModel?.version ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: tr('is_available_to_download')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(tr('cancel')),
          ),
          MaterialButton(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            color: appPrimaryColor,
            textColor: Colors.white,
            onPressed: () async {
              Navigator.of(context).pop(true);
              onDownloadStart?.call();
            },
            child: Text(tr('update')),
          ),
        ],
      );
    },
  );
  return update ?? false;
}

/// function to ask for sync offline saved data such as offline orders, credit notes, etc.
/// [context] is the context of the screen
/// [isForceSync] is the flag to force sync
Future<void> showOfflineDataReadyForSync(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(tr('sync_data')),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18.0,
        ),
        content: Text(tr('offline_sync_data_is_available_to_sync')),
        contentTextStyle: const TextStyle(color: Colors.black, fontSize: 16.0),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(tr('cancel')),
          ),
          MaterialButton(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            color: appPrimaryColor,
            textColor: Colors.white,
            onPressed: () async {
              var routeTo = OfflineChangeSetWidget.routeName;
              await FullVendor.instance.pushNamed(routeTo, parameters: false);
              var offlineChangeSetCount =
                  await OfflineSavedDB.instance.offlineChangeSetCount();
              if (offlineChangeSetCount > 0) return;
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            child: Text(tr('perform_a_data_sync')),
          ),
        ],
      );
    },
  );
}
