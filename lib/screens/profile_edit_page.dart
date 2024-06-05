import 'package:FullVendor/application/application_global_keys.dart';
import 'package:FullVendor/model/login_model.dart';
import 'package:FullVendor/network/apis.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/theme.dart';
import '../widgets/app_theme_widget.dart';
import '../widgets/salesman/salesman_fragment_header_widget.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});
  static const String routeName = '/profile/edit';

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    _firstNameController.text = LoginDataModel.instance.info?.firstName ?? '';
    _lastNameController.text = LoginDataModel.instance.info?.lastName ?? '';
    _phoneController.text = LoginDataModel.instance.info?.phoneNumber ?? '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      useBottomPadding: true,
      appBar: SalesmanTopBar(
        title: 'Edit Profile',
        onBackPress: () async {
          Navigator.pop(context);
        },
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: MaterialButton(
              onPressed: isLoading ? null : buttonClickAction,
              textColor: Colors.white,
              color: appPrimaryColor,
              disabledColor: Colors.grey.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minWidth: double.infinity,
              height: 50,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Text(tr('save_profile_uppercase')),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          _editTextField(tr('first_name'), controller: _firstNameController),
          _editTextField(tr('last_name'), controller: _lastNameController),
          _nonEditableTextField(
            tr('company_name'),
            LoginDataModel.instance.info?.companyName ?? '',
          ),
          _nonEditableTextField(
            tr('company_id'),
            LoginDataModel.instance.info?.companyId ?? '',
          ),
          _nonEditableTextField(
            tr('email'),
            LoginDataModel.instance.info?.email ?? '',
          ),
          _editTextField(tr('phone'),
              controller: _phoneController, isNumber: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _editTextField(
    String title, {
    required TextEditingController controller,
    bool isNumber = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 2, left: 18),
          child: Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 16, right: 16, top: 0),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFC8C8C8), width: 1),
          ),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: controller,
            inputFormatters: [
              if (isNumber) FilteringTextInputFormatter.digitsOnly,
            ],
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              constraints: const BoxConstraints(minHeight: 55),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
            ),
            maxLines: 1,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _nonEditableTextField(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 0, bottom: 2, left: 2),
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5E5),
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(minHeight: 55),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
          ),
        ],
      ),
    );
  }

  Future<void> buttonClickAction() async {
    if (isLoading) return;
    isLoading = true;
    setState(() {});
    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      isLoading = false;
      setState(() {});
    });
    bool isConnected =
        (await Connectivity().checkConnectivity()) != ConnectivityResult.none;
    if (!isConnected) {
      FullVendor.instance.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(tr('no_internet_connection')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String phone = _phoneController.text.trim();
    dynamic response = await Apis.instance.updateProfile(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phone,
    );
    isLoading = false;
    if (!mounted) return;
    setState(() {});
    if (response['status'] == '0') {
      FullVendor.instance.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(response['error'] ?? tr('something_went_wrong')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    LoginDataModel.instance.info?.firstName = firstName;
    LoginDataModel.instance.info?.lastName = lastName;
    LoginDataModel.instance.info?.phoneNumber = phone;
    LoginDataModel.instance.save();
    if (!mounted) return;
    setState(() {});
    FullVendor.instance.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(tr('profile_updated_successfully')),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }
}
