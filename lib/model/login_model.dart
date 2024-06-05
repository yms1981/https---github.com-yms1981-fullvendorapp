import 'dart:convert';

import 'package:FullVendor/db/shared_pref.dart';

class LoginDataModel {
  String? status;
  String? error;
  String? userType;
  Info? info;

  static LoginDataModel? instanceValue;

  static LoginDataModel get instance {
    instanceValue ??= LoginDataModel.fromSharedPref();
    return instanceValue!;
  }

  LoginDataModel({this.status, this.userType, this.info, this.error});

  LoginDataModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    userType = json['user_type'];
    info = json['info'] != null ? Info.fromJson(json['info']) : null;
    error = json['error'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['user_type'] = userType;
    if (info != null) {
      data['info'] = info!.toJson();
    }
    data['error'] = error;
    return data;
  }

  LoginDataModel.fromSharedPref() {
    String? jsonEncoded = FullVendorSharedPref.instance.userInfo;
    if (jsonEncoded.isEmpty) {
      return;
    }
    Map<String, dynamic> json = jsonDecode(jsonEncoded);
    status = json['status'];
    userType = json['user_type'];
    info = json['info'] != null ? Info.fromJson(json['info']) : null;
    error = json['error'];
  }

  Future<void> save() async {
    String jsonEncoded = jsonEncode(toJson());
    FullVendorSharedPref.instance.userInfo = jsonEncoded;
  }
}

class Info {
  String? userId;
  String? uniqueId;
  String? firstName;
  String? lastName;
  String? email;
  String? phoneNumber;
  String? profileImage;
  String? profile;
  String? companyId;
  String? companyName;
  String? languageId;
  String? orderDiscount;
  String? orderNetDiscount;
  String? canChangePrice;
  String? canSendCatalog;
  String? canCreateCustomer;
  String? addcustomer;
  String? updatecustomer;
  String? sendcatalog;
  TermSales? termSales;
  TermSales? customerGroups;
  TermSales? countryInfo;

  Info(
      {this.userId,
      this.uniqueId,
      this.firstName,
      this.lastName,
      this.email,
      this.phoneNumber,
      this.profileImage,
      this.profile,
      this.companyId,
      this.companyName,
      this.languageId,
      this.orderDiscount,
      this.orderNetDiscount,
      this.canChangePrice,
      this.canSendCatalog,
      this.canCreateCustomer,
      this.addcustomer,
      this.updatecustomer,
      this.sendcatalog,
      this.termSales,
      this.customerGroups,
      this.countryInfo});

  Info.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    uniqueId = json['unique_id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    email = json['email'];
    phoneNumber = json['phone_number'];
    profileImage = json['profile_image'];
    profile = json['profile'];
    companyId = json['company_id'];
    companyName = json['company_name'];
    languageId = json['language_id'];
    orderDiscount = json['order_discount'];
    orderNetDiscount = json['order_net_discount'];
    canChangePrice = json['can_change_price'];
    canSendCatalog = json['can_send_catalog'];
    canCreateCustomer = json['can_create_customer'];
    addcustomer = json['addcustomer'];
    updatecustomer = json['updatecustomer'];
    sendcatalog = json['sendcatalog'];
    termSales = json['term_sales'] != null
        ? TermSales.fromJson(json['term_sales'])
        : null;
    customerGroups = json['customer_groups'] != null
        ? TermSales.fromJson(json['customer_groups'])
        : null;
    countryInfo = json['country_info'] != null
        ? TermSales.fromJson(json['country_info'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user_id'] = userId;
    data['unique_id'] = uniqueId;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['email'] = email;
    data['phone_number'] = phoneNumber;
    data['profile_image'] = profileImage;
    data['profile'] = profile;
    data['company_id'] = companyId;
    data['company_name'] = companyName;
    data['language_id'] = languageId;
    data['order_discount'] = orderDiscount;
    data['order_net_discount'] = orderNetDiscount;
    data['can_change_price'] = canChangePrice;
    data['can_send_catalog'] = canSendCatalog;
    data['can_create_customer'] = canCreateCustomer;
    data['addcustomer'] = addcustomer;
    data['updatecustomer'] = updatecustomer;
    data['sendcatalog'] = sendcatalog;
    if (termSales != null) {
      data['term_sales'] = termSales!.toJson();
    }
    if (customerGroups != null) {
      data['customer_groups'] = customerGroups!.toJson();
    }
    if (countryInfo != null) {
      data['country_info'] = countryInfo!.toJson();
    }
    return data;
  }
}

class TermSales {
  String? id;
  String? name;

  TermSales({this.id, this.name});

  TermSales.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    return data;
  }
}
