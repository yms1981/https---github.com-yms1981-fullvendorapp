import 'package:FullVendor/application/application_global_keys.dart';
import 'package:FullVendor/application/theme.dart';
import 'package:FullVendor/model/login_model.dart';
import 'package:FullVendor/screens/profile_edit_page.dart';
import 'package:FullVendor/widgets/app_theme_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../db/shared_pref.dart';
import '../widgets/profile_pic_header.dart';
import '../widgets/salesman/salesman_fragment_header_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  static const String routeName = '/profile';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      useBottomPadding: true,
      appBar: SalesmanTopBar(
        title: 'Profile',
        onBackPress: () {
          Navigator.pop(context);
        },
      ),
      body: ListView(
        children: [
          ProfileHeader(
            title: FullVendorSharedPref.instance.userType == "1"
                ? 'Salesman'
                : 'Warehouse manager',
            name: LoginDataModel.instance.info?.firstName ?? '',
            role: LoginDataModel.instance.info?.companyName ?? '',
            color: Colors.black,
          ),
          _textFields(
            tr('company_name'),
            LoginDataModel.instance.info?.companyName ?? '',
          ),
          _textFields(
            tr('company_id'),
            LoginDataModel.instance.info?.companyId ?? '',
          ),
          _textFields(
            tr('email'),
            LoginDataModel.instance.info?.email ?? '',
          ),
          /*(LoginDataModel.instance.info?.phoneNumber ?? '').isEmpty
              ? const SizedBox()
              :*/
          _textFields(
              tr('phone'), LoginDataModel.instance.info?.phoneNumber ?? ''),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: MaterialButton(
              onPressed: () async {
                await FullVendor.instance.pushNamed(ProfileEditPage.routeName);
                if (!mounted) return;
                setState(() {});
              },
              textColor: Colors.white,
              color: appPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minWidth: double.infinity,
              height: 50,
              child: Text(tr('edit_profile_uppercase')),
            ),
          ),
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
