import 'package:FullVendor/widgets/app_theme_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../application/theme.dart';
import '../../common_widgets/text_input_field.dart';
import '../../model/login_model.dart';
import '../../model/new_customer_used_data_model.dart';
import '../../network/apis.dart';
import '../../widgets/salesman/salesman_fragment_header_widget.dart';

class AddCustomerPage extends StatefulWidget {
  const AddCustomerPage({super.key});

  static const String routeName = '/salesman/add-customer';

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final TextEditingController _businessName = TextEditingController();
  final TextEditingController _contactName = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _zone = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _state = TextEditingController();
  final TextEditingController _country = TextEditingController();
  final TextEditingController _zipCode = TextEditingController();
  final TextEditingController _contactNumber = TextEditingController();
  final TextEditingController _cellPhone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _textID = TextEditingController();
  final TextEditingController _note = TextEditingController();
  String selectedPaymentCondition =
      LoginDataModel.instance.info?.termSales?.id ?? '';
  String selectedRole = LoginDataModel.instance.info?.customerGroups?.id ?? '';

  bool isLoading = false;
  PaymentTypeOptionsDataModel? paymentTypeOptionsDataModel;
  GroupTypeOptionsDataModel? groupTypeOptionsDataModel;

  @override
  void initState() {
    super.initState();
    refreshData().then(
      (value) {
        isLoading = false;
        if (!mounted) return;
        setState(() {});
      },
      onError: (error) {
        isLoading = false;
        if (!mounted) return;
        setState(() {});
      },
    );
    // post draw call back
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (LoginDataModel.instance.info?.canCreateCustomer != "1") {
        Navigator.pop(context);
        SnackBar snackBar = SnackBar(
          content: Text(tr('no_permission_to_create_customer')),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return;
      }
      _country.text = LoginDataModel.instance.info?.countryInfo?.name ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      appBar: SalesmanTopBar(
        title: tr('add_customer'),
        onBackPress: () async {
          Navigator.of(context).pop();
        },
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('add_customer'),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              const SizedBox(height: 16),
              TextInputField(
                controller: _businessName,
                label: tr('business_name'),
                hintText: tr('enter_business_name'),
              ),
              const SizedBox(height: 10),
              TextInputField(
                controller: _contactName,
                label: tr('contact_name'),
                hintText: tr('enter_contact_name'),
              ),
              const SizedBox(height: 10),
              TextInputField(
                controller: _address,
                label: tr('address'),
                hintText: tr('enter_address'),
              ),
              const SizedBox(height: 10),
              TextInputField(
                controller: _zone,
                label: tr('zone'),
                hintText: tr('enter_zone'),
              ),
              const SizedBox(height: 10),
              TextInputField(
                controller: _city,
                label: tr('city'),
                hintText: tr('enter_city'),
              ),
              const SizedBox(height: 10),
              TextInputField(
                controller: _state,
                label: tr('state'),
                hintText: tr('enter_state'),
              ),
              const SizedBox(height: 10),
              TextInputField(
                controller: _country,
                label: tr('country'),
                hintText: tr('enter_country'),
              ),
              const SizedBox(height: 10),
              TextInputField(
                controller: _zipCode,
                label: tr('zip_code'),
                hintText: tr('enter_zip_code'),
              ),
              const SizedBox(height: 10),
              TextInputField(
                controller: _contactNumber,
                label: tr('contact_number'),
                hintText: tr('enter_contact_number'),
              ),
              const SizedBox(height: 10),
              TextInputField(
                controller: _cellPhone,
                label: tr('cell_phone'),
                hintText: tr('enter_cell_phone'),
              ),
              const SizedBox(height: 10),
              TextInputField(
                controller: _email,
                label: tr('email'),
                hintText: tr('enter_email'),
              ),
              const SizedBox(height: 10),
              TextInputField(
                controller: _textID,
                label: tr('text_id'),
                hintText: tr('enter_text_id'),
              ),
              // const SizedBox(height: 10),
              // TextInputField(
              //   controller: _discount,
              //   label: tr('discount'),
              //   hintText: tr('enter_discount'),
              //   keyboardType: TextInputType.number,
              // ),
              const SizedBox(height: 10),
              Text(tr('payment_condition')),
              paymentConditionWidget(),
              const SizedBox(height: 16),
              Text(tr('select_role')),
              roleWidget(),
              const SizedBox(height: 16),
              TextInputField(
                controller: _note,
                label: tr('note'),
                hintText: tr('note_optional'),
                keyboardType: TextInputType.multiline,
                minLines: 5,
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              if (isLoading) const LinearProgressIndicator(),
              MaterialButton(
                minWidth: double.infinity,
                color: appPrimaryColor,
                disabledColor: Colors.grey.shade100,
                textColor: isLoading ? Colors.grey : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                onPressed: isLoading
                    ? null
                    : () async {
                        if (isLoading) return;
                        String? text;
                        if (_businessName.text.isEmpty) {
                          text = tr('please_enter_business_name');
                        } else if (_contactName.text.isEmpty) {
                          text = tr('please_enter_contact_name');
                        } else if (_email.text.isEmpty) {
                          text = tr('please_enter_email');
                        } else if (selectedPaymentCondition.isEmpty) {
                          text = tr('please_select_payment_condition');
                        } else if (selectedRole.isEmpty) {
                          text = tr('please_select_role');
                        }
                        if (text != null) {
                          SnackBar snackBar = SnackBar(content: Text(text));
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                          return;
                        }

                        isLoading = true;
                        setState(() {});
                        dynamic response = await Apis().addCustomer(
                          businessName: _businessName.text,
                          contactName: _contactName.text,
                          address: _address.text,
                          zone: _zone.text,
                          city: _city.text,
                          state: _state.text,
                          country: _country.text,
                          zipCode: _zipCode.text,
                          contactNumber: _contactNumber.text,
                          cellPhone: _cellPhone.text,
                          email: _email.text,
                          textID: _textID.text,
                          note: _note.text,
                          selectedRole: selectedRole,
                          selectedPaymentCondition: selectedPaymentCondition,
                        );
                        if (!mounted) return;
                        if (response is String) {
                          SnackBar snackBar = SnackBar(content: Text(response));
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        } else {
                          String status = response['status']?.toString() ?? '';
                          String message =
                              (response['message'] ?? response['error'])
                                      ?.toString() ??
                                  '';
                          if (status == '1') {
                            SnackBar snackBar = SnackBar(
                              content: Text(message),
                            );
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                            Navigator.pop(context, true);
                          } else {
                            SnackBar snackBar = SnackBar(
                              content: Text(message),
                            );
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          }
                        }
                        if (!mounted) return;
                        isLoading = false;
                        setState(() {});
                      },
                child: Text(tr('save_new_customer')),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget paymentConditionWidget() {
    return Wrap(
      children: paymentTypeOptionsDataModel?.list
              ?.map(
                (e) => InkWell(
                  onTap: () {
                    selectedPaymentCondition = e.termId ?? '';
                    setState(() {});
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<String>(
                        value: e.termId ?? '',
                        activeColor: appPrimaryColor,
                        groupValue: selectedPaymentCondition,
                        onChanged: (value) {
                          selectedPaymentCondition = value ?? '';
                          setState(() {});
                        },
                      ),
                      Text(e.name ?? ''),
                    ],
                  ),
                ),
              )
              .toList() ??
          [
            InkWell(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<String>(
                    value: LoginDataModel.instance.info?.termSales?.id ?? '',
                    activeColor: appPrimaryColor,
                    groupValue: selectedPaymentCondition,
                    onChanged: (value) {
                      selectedPaymentCondition = value ?? '';
                      setState(() {});
                    },
                  ),
                  Text(LoginDataModel.instance.info?.termSales?.name ?? ''),
                ],
              ),
            )
          ],
    );
  }

  Widget roleWidget() {
    return Wrap(
      children: groupTypeOptionsDataModel?.list
              ?.map(
                (e) => InkWell(
                  onTap: () {
                    selectedRole = e.groupId ?? '';
                    setState(() {});
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<String>(
                        value: e.groupId ?? '',
                        activeColor: appPrimaryColor,
                        groupValue: selectedRole,
                        onChanged: (value) {
                          selectedRole = value ?? '';
                          setState(() {});
                        },
                      ),
                      Text(e.name ?? ''),
                    ],
                  ),
                ),
              )
              .toList() ??
          [
            InkWell(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<String>(
                    value:
                        LoginDataModel.instance.info?.customerGroups?.id ?? '',
                    activeColor: appPrimaryColor,
                    groupValue: selectedRole,
                    onChanged: (value) {
                      selectedRole = value ?? '';
                      setState(() {});
                    },
                  ),
                  Text(
                    LoginDataModel.instance.info?.customerGroups?.name ?? '',
                  ),
                ],
              ),
            )
          ],
    );
  }

  Future<dynamic> refreshData() async {
    isLoading = true;
    setState(() {});
    dynamic loadAvailableTermsOfSalesListResponse =
        await Apis().loadAvailableTermsOfSalesList();
    paymentTypeOptionsDataModel = PaymentTypeOptionsDataModel.fromJson(
        loadAvailableTermsOfSalesListResponse);

    dynamic groupListResponse = await Apis().loadAvailableGroups();
    groupTypeOptionsDataModel =
        GroupTypeOptionsDataModel.fromJson(groupListResponse);

    return true;
  }
}
