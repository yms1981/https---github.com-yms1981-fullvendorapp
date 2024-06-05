import 'dart:io';

import 'package:FullVendor/application/theme.dart';
import 'package:FullVendor/db/offline_saved_db.dart';
import 'package:FullVendor/network/apis.dart';
import 'package:FullVendor/utils/extensions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../application/application_global_keys.dart';
import '../common_widgets/text_input_field.dart';
import '../db/shared_pref.dart';
import '../generated/assets.dart';
import '../model/login_model.dart';
import 'change_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const String routeName = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // for warehouse: borujnudman@hotmail.com
  // for salesman: claudio@prodytec.com
  final TextEditingController _emailController =
      TextEditingController(text: FullVendorSharedPref.instance.email);
  final TextEditingController _passwordController =
      TextEditingController(text: FullVendorSharedPref.instance.password);
  bool _isPasswordVisible = false;
  bool _isSalesManLogin = FullVendorSharedPref.instance.userType != "2";
  bool _isLoginInProgress = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(Assets.imagesLoginBg),
                fit: BoxFit.fill,
              ),
              gradient: appPrimaryGradient,
            ),
          ),
          Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          height: 131,
                          width: 111,
                          child: Image.asset(Assets.assetsLogoWhite),
                        ),
                      ),
                    ),
                    const Text(
                      "Login to FullVendor",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxHeight: 400, maxWidth: 600),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: ListView(
                  // itemExtent: 100,
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(child: loginTypeWidget(true)),
                        Expanded(child: loginTypeWidget(false)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextInputField(
                      controller: _emailController,
                      label: tr("email"),
                      hintText: tr("enter_email"),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextInputField(
                      controller: _passwordController,
                      label: tr('password'),
                      hintText: tr('enter_password'),
                      obscureText: !_isPasswordVisible,
                      suffixIcon: IconButton(
                        onPressed: () {
                          _isPasswordVisible = !_isPasswordVisible;
                          setState(() {});
                        },
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    loginButton(),
                    forgotPasswordButton(),
                    const SizedBox(height: 6),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget loginButton() {
    return Container(
      width: double.infinity,
      height: 45,
      margin: const EdgeInsets.only(top: 16, bottom: 6),
      child: MaterialButton(
        color: const Color(0xFFCC2028),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        disabledColor: Colors.grey.shade400,
        onPressed: _isLoginInProgress
            ? null
            : () async {
                _isLoginInProgress = true;
                setState(() {});
                try {
                  await loginProcess();
                } catch (e) {
                  if (kDebugMode) {
                    print(e.toString());
                    print(StackTrace.current);
                  }
                  Fluttertoast.showToast(msg: e.toString());
                }
                if (!mounted) return;
                _isLoginInProgress = false;
                setState(() {});
              },
        child: const Text(
          "Login",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget forgotPasswordButton() {
    return TextButton(
      onPressed: () async {
        await FullVendor.instance.pushNamed(UpdatePasswordPage.routeNameResetPassword);
        setState(() {});
      },
      child: Text(tr('forgot_password')),
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
            color: _isSalesManLogin == isSalesManLogin ? Colors.white : const Color(0xFFCC2028),
          ),
        ),
      ),
    );
  }

  Future<void> loginProcess() async {
    String loginType = _isSalesManLogin ? "1" : "2";
    String username = _emailController.text.trim();
    String password = _passwordController.text.trim();
    dynamic response;
    try {
      response = await Apis().login(
        username: username,
        password: password,
        loginType: loginType,
      );
    } catch (e) {
      ///  uncomment below code to work with offline login
      // response = await OfflineSavedDB.instance.offlineLogin(
      //   username: username,
      //   password: password,
      //   loginType: loginType,
      // );
      if (response != null) {
        FullVendorSharedPref.instance.isOfflineLogin = true;
      } else {
        response = {'error': tr('no_internet_connection')};
      }
    }
    if (!mounted) return;
    if (response == null) {
      if (!mounted) return;
      bool isConnected =
          (await Connectivity().checkConnectivity()).firstOrNull == ConnectivityResult.none;
      if (isConnected) {
        if (mounted) {
          context.showSnackBar(tr('no_internet_connection'));
        }
        return;
      }
      if (mounted) {
        context.showSnackBar(tr('something_went_wrong'));
      }
      return;
    }
    if (response is String) {
      context.showSnackBar(response);
      return;
    }
    LoginDataModel? loginDataModel = LoginDataModel.fromJson(response);
    if (!mounted) {
      return;
    }
    if (loginDataModel.status != "1") {
      context.showSnackBar(loginDataModel.error ?? tr('something_went_wrong'));
      return;
    }

    // if session is of last login user then no problem, else delete any other db files
    if (FullVendorSharedPref.instance.email != username) {
      List<String> files = await listFilesInDBDirectory();
      final String userId = loginDataModel.info?.userId ?? "0";
      final String dbName = 'gallery_$userId.db';
      for (String file in files) {
        if (file.contains("gallery_") && file != dbName) {
          await File(file).delete();
        }
      }
    } else {
      if (kDebugMode) {
        print("Same user");
      }
    }

    FullVendorSharedPref.instance.email = username;
    FullVendorSharedPref.instance.password = password;
    FullVendorSharedPref.instance.isLoggedIn = true;
    String userType = loginDataModel.userType ?? "1";
    FullVendorSharedPref.instance.userType = userType;
    await OfflineSavedDB.instance.saveOfflineLoginData(
      email: username,
      password: password,
      userType: userType,
      sessionData: loginDataModel,
    );
    await loginDataModel.save();
    LoginDataModel.instanceValue = null;

    Locale newLocale = loginDataModel.info?.languageId == "1"
        ? const Locale('en', 'US')
        : const Locale('es', 'ES');
    if (!mounted) return;
    context.setLocale(newLocale);

    Navigator.of(context).pop();
  }
}
