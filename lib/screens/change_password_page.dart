import 'package:FullVendor/network/apis.dart';
import 'package:FullVendor/widgets/app_theme_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../application/theme.dart';
import '../widgets/salesman/salesman_fragment_header_widget.dart';

class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({super.key, required this.isRestPassword});
  static const String routeName = '/update/password';
  static const String routeNameResetPassword = '/reset-password';
  final bool isRestPassword;

  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  bool isLoading = false;
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool isOtpSent = false;
  bool _isSalesManLogin = true;
  bool otpSendInProgress = false;

  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      appBar: SalesmanTopBar(
        title: widget.isRestPassword
            ? tr('reset_password')
            : tr('update_password'),
        onBackPress: () {
          Navigator.pop(context);
        },
      ),
      body: ListView(
        children: <Widget>[
          if (widget.isRestPassword)
            _editTextField(
              tr('email'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            )
          else
            _editTextField(
              tr('old_password'),
              controller: _oldPasswordController,
              isPassword: true,
            ),
          if (widget.isRestPassword)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(child: loginTypeWidget(true)),
                      Expanded(child: loginTypeWidget(false)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: MaterialButton(
                    onPressed: otpSendInProgress ? null : sendOTP,
                    textColor: Colors.white,
                    color: appPrimaryColor,
                    disabledColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minWidth: double.infinity,
                    height: 50,
                    child: Text(tr('send_otp_uppercase')),
                  ),
                ),
                if (isOtpSent)
                  _editTextField(
                    'OTP',
                    controller: _otpController,
                    isNumber: true,
                  ),
              ],
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Divider(height: 10),
          ),
          if (isOtpSent || !widget.isRestPassword)
            _editTextField(
              tr('new_password'),
              controller: _newPasswordController,
              isPassword: true,
            ),
          if (isOtpSent || !widget.isRestPassword)
            _editTextField(
              tr('confirm_password'),
              controller: _confirmPasswordController,
              isPassword: true,
            ),
          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: MaterialButton(
              onPressed: isLoading
                  ? null
                  : (widget.isRestPassword ? resetPassword : updatePassword),
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
                  : Text(
                      widget.isRestPassword
                          ? tr('reset_password').toUpperCase()
                          : tr('update_password').toUpperCase(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editTextField(
    String title, {
    required TextEditingController controller,
    bool isNumber = false,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
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
            obscureText: isPassword,
            keyboardType: isNumber ? TextInputType.number : keyboardType,
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

  Widget loginTypeWidget(bool isSalesManLogin) {
    return InkWell(
      onTap: () {
        _isSalesManLogin = !_isSalesManLogin;
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 430),
        constraints: const BoxConstraints(minHeight: 45),
        decoration: BoxDecoration(
          color: _isSalesManLogin == isSalesManLogin
              ? const Color(0xFFCC2028)
              : const Color(0xFFFFF2F2),
          borderRadius: BorderRadius.horizontal(
            left: isSalesManLogin ? const Radius.circular(16) : Radius.zero,
            right: isSalesManLogin ? Radius.zero : const Radius.circular(16),
          ),
          border: Border.all(color: const Color(0xFFCC2028)),
        ),
        alignment: Alignment.center,
        child: Text(
          isSalesManLogin ? "Salesman" : "Warehouse Manager",
          style: TextStyle(
            color: _isSalesManLogin == isSalesManLogin
                ? Colors.white
                : const Color(0xFFCC2028),
          ),
        ),
      ),
    );
  }

  Future<void> sendOTP() async {
    String email = _emailController.text.trim();
    bool isEmailValid =
        RegExp(r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$')
            .hasMatch(email);
    // hide keyboard
    FocusScope.of(context).requestFocus(FocusNode());
    if (email.isEmpty || !isEmailValid) {
      Fluttertoast.showToast(msg: tr('enter_valid_email'));
      return;
    }
    String loginType = _isSalesManLogin ? "1" : "2";
    try {
      otpSendInProgress = true;
      setState(() {});
      dynamic response = await Apis().generateResetOtp(email, loginType);
      print(response);
      if (response['status'] == "1") {
        isOtpSent = true;
      } else {
        Fluttertoast.showToast(
            msg: response['message'] ?? 'Something went wrong');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Something went wrong');
    } finally {
      if (mounted) {
        otpSendInProgress = false;
        setState(() {});
      }
    }
  }

  Future<void> resetPassword() async {
    String newPassword = _newPasswordController.text;
    String confirmPassword = _confirmPasswordController.text;

    FocusNode().requestFocus(FocusNode());

    if (newPassword.length < 6) {
      Fluttertoast.showToast(msg: tr('password_must_be_at_least_6_characters'));
      return;
    }

    if (newPassword != confirmPassword) {
      Fluttertoast.showToast(msg: tr('passwords_do_not_match'));
      return;
    }
    if (!isOtpSent) {
      Fluttertoast.showToast(msg: tr('send_otp_first'));
      return;
    }
    isLoading = true;
    setState(() {});
    try {
      String userType = _isSalesManLogin ? "1" : "2";
      dynamic response = await Apis().resetPassword(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
        password: newPassword,
        userType: userType,
      );
      if (response['status'] == "1") {
        Fluttertoast.showToast(msg: tr('password_updated_successfully'));
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        Fluttertoast.showToast(
            msg: response['message'] ?? tr('something_went_wrong'));
      }
    } catch (e) {
      Fluttertoast.showToast(msg: tr('something_went_wrong'));
    } finally {
      if (mounted) {
        isLoading = false;
        setState(() {});
      }
    }
  }

  Future<void> updatePassword() async {
    isLoading = true;
    setState(() {});
    if (_newPasswordController.text.length < 6) {
      Fluttertoast.showToast(
          msg: tr('password_must_be_at_least_6_characters)'));
      return;
    }
    try {
      dynamic response = await Apis().updatePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (response['status'] == "1") {
        Fluttertoast.showToast(msg: tr('password_updated_successfully'));
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        Fluttertoast.showToast(
            msg: response['message'] ?? tr('something_went_wrong'));
      }
    } catch (e) {
      Fluttertoast.showToast(msg: tr('something_went_wrong'));
    } finally {
      if (mounted) {
        isLoading = false;
        setState(() {});
      }
    }
  }
}
