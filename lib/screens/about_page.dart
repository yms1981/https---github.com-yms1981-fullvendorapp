import 'package:FullVendor/db/synced_db.dart';
import 'package:FullVendor/generated/assets.dart';
import 'package:FullVendor/widgets/app_theme_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../application/theme.dart';
import '../widgets/salesman/salesman_fragment_header_widget.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});
  static const String routeName = '/about';

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  PackageInfo? platformInfo;
  String dbVersion = '';
  String lastSync = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((value) {
      platformInfo = value;
      setState(() {});
    });
    SyncedDB.instance.getSyncInfo().then((value) {
      dbVersion = value['version']?.toString() ?? '';
      lastSync = value['fecha']?.toString() ?? '';
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      appBar: SalesmanTopBar(
        title: 'About',
        onBackPress: () {
          Navigator.pop(context);
        },
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 300,
            child: Image.asset(Assets.assetsAppLogo),
          ),
          _textFields(tr('app_name'), platformInfo?.appName ?? ''),
          _textFields(tr('version'), platformInfo?.version ?? ''),
          _textFields(tr('build_number'), platformInfo?.buildNumber ?? ''),
          _textFields(tr('database_version'), dbVersion),
          _textFields('Last Sync', lastSync),
          InkWell(
            onTap: () async {
              String url = 'https://www.fullvendor.com/';
              await launchUrlString(url, mode: LaunchMode.externalApplication);
            },
            child: _textFields('Website', 'www.fullvendor.com'),
          ),
          const SizedBox(height: 26),
        ],
      ),
    );
  }

  Widget _textFields(String label, String value) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: appPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
