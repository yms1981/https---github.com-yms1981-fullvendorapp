import 'dart:convert';
import 'dart:io';

import 'package:FullVendor/db/shared_pref.dart';
import 'package:FullVendor/model/customer_list_data_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../db/synced_db.dart';
import '../model/available_language_data_model.dart';
import '../model/login_model.dart';
import '../model/place_order_model.dart';
import '../model/product_list_data_model.dart';
import '../model/warehouse_history_data_model.dart';
import '../model/warehouse_order_dispatch_api_model.dart';
import '../utils/extensions.dart';

const String baseUrl = 'https://app.fullvendor.com/restapi/api/';
String token = 'f008aa014308059be6c1c20ed70a006e';
String deviceDetails = '';
String versionName = '1.0.0';
String versionCode = '1';

class Apis {
  static final Apis _instance = Apis._internal();

  static Apis get instance => _instance;

  Apis._internal() {
    dio.options.sendTimeout = const Duration(seconds: 7);
    dio.options.connectTimeout = const Duration(seconds: 7);
//    dio.options.receiveTimeout = const Duration(seconds: 7);
  }

  factory Apis() {
    return _instance;
  }

  final Dio dio = Dio();

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await dio.get(
      '$baseUrl$path',
      queryParameters: queryParameters,
      options: Options(headers: {"x-api-key": token}),
    );
    return response.data;
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic data,
  }) async {
    //queryParameters?['language_id'] = LoginDataModel.instance.info?.languageId;
    print("Positing json data to server path :'$baseUrl$path");
    print(jsonEncode(data));
    try {
      final response = await dio.post(
        '$baseUrl$path',
        //  queryParameters: queryParameters,
        options: Options(
          headers: {"x-api-key": token},
          contentType: 'application/json',
          followRedirects: true,
          responseType: ResponseType.json,
        ),
        data: data,
      );
      dynamic responseData = response.data;
      // print(jsonEncode(responseData));
      return responseData;
    } on DioException catch (e) {
      if (e.response != null) {
        dynamic data = e.response?.data;
        print(jsonEncode(data));
        return data;
      } else {
        rethrow;
      }
    } on Exception catch (_) {
      rethrow;
    }
  }

  // Future<String?> updateProfile() async {}
  // Future<String?> userInfo() async {}
  // Future<String?> changePassword() async {}
  // Future<String?> productDetails() async {}
  // Future<String?> languages() async {}

  Future<dynamic> categoryList() async {
    LoginDataModel userProfile = LoginDataModel.instance;
    return await post(
      'categoryList',
      data: {
        'language_id': userProfile.info?.languageId ?? '1',
        'company_id': userProfile.info?.companyId ?? '3'
      },
    );
  }

  Future<dynamic> productList({String? categoryId}) async {
    LoginDataModel userProfile = LoginDataModel.instance;
    Customer? defaultCustomer = defaultCustomerNotifier.value;
    //productList
    Map<dynamic, dynamic> data = {
      'language_id': userProfile.info?.languageId ?? '1',
      'company_id': userProfile.info?.companyId ?? '3',
      'customer_id': defaultCustomer?.customerId ?? '-1',
    };
    if (categoryId != null) {
      data['category_id'] = categoryId;
    }
    return await post('productList', data: data);
  }

  Future<dynamic> login({
    required String username,
    required String password,
    required String loginType,
  }) async {
    try {
      return await post('login', data: {
        'email': username,
        'password': password,
        'user_type': loginType,
      });
    } on DioException catch (e) {
      var data = e.response?.data;
      if (data == null) rethrow;
      return data;
    } on Exception catch (_) {
      rethrow;
    }
  }

  /// api to get the list of customers
  Future<dynamic> getCustomerList({required bool isWarehouse}) async {
    LoginDataModel userProfile = LoginDataModel.instance;
    Map<String, dynamic> data = {
      'language_id': userProfile.info?.languageId ?? '1',
      'company_id': userProfile.info?.companyId ?? '-1',
    };
    if (!isWarehouse) {
      data['user_id'] = userProfile.info?.userId ?? '-1';
    }
    return await post(isWarehouse ? 'customersList' : 'customerList', data: data);
  }

  ///api to get the current or updated details of the customer
  ///params [customerId] is the id of the customer
  Future<dynamic> getCustomerDetails({required String customerId}) async {
    LoginDataModel userProfile = LoginDataModel.instance;
    return await post('customerDetails', data: {
      'language_id': userProfile.info?.languageId ?? '-1',
      'user_id': userProfile.info?.userId ?? '-1',
      'company_id': userProfile.info?.companyId ?? '-1',
      'customer_id': customerId,
    });
  }

  Future<dynamic> loadOrderHistory() async {
    LoginDataModel userProfile = LoginDataModel.instance;
    return await post('orderList', data: {
      'language_id': userProfile.info?.languageId ?? '1',
      'user_id': userProfile.info?.userId ?? '8',
      'company_id': userProfile.info?.companyId ?? '3',
      'customer_id': defaultCustomerNotifier.value?.customerId ?? '',
    });
  }

  Future<dynamic> loadAvailableTermsOfSalesList() async {
    LoginDataModel userProfile = LoginDataModel.instance;
    return await post('termsOfSalesList', data: {
      'language_id': userProfile.info?.languageId ?? '1',
      'company_id': userProfile.info?.companyId ?? '3',
    });
  }

  Future<dynamic> loadAvailableGroups() async {
    LoginDataModel userProfile = LoginDataModel.instance;
    return await post('customerGroupsList', data: {
      'language_id': userProfile.info?.languageId ?? '1',
      'company_id': userProfile.info?.companyId ?? '3',
    });
  }

  Future<dynamic> addCustomer({
    required String businessName,
    required String contactName,
    required String address,
    required String zone,
    required String city,
    required String state,
    required String country,
    required String zipCode,
    required String contactNumber,
    required String cellPhone,
    required String email,
    required String textID,
    required String note,
    required String selectedRole,
    required String selectedPaymentCondition,
  }) async {
    Map<String, String?> requestData = {};
    LoginDataModel userProfile = LoginDataModel.instance;
    requestData['user_id'] = userProfile.info?.userId ?? '8';
    requestData['language_id'] = userProfile.info?.languageId ?? '1';
    requestData['company_id'] = userProfile.info?.companyId ?? '3';
    requestData['customerId'] = null;
    requestData['business_name'] = businessName;
    requestData['name'] = contactName;
    requestData['commercial_address'] = address;
    requestData['commercial_delivery_address'] = '';
    requestData['dispatch_address'] = '';
    requestData['dispatch_delivery_address'] = '';
    requestData['catalog_emails'] = '';

    requestData['commercial_zone'] = zone;
    requestData['dispatch_zone'] = zone;
    requestData['commercial_city'] = city;
    requestData['dispatch_city'] = city;
    requestData['dispatch_state'] = city;
    requestData['commercial_state'] = state;
    requestData['commercial_country'] = country;
    requestData['dispatch_country'] = country;
    requestData['commercial_zip_code'] = zipCode;
    requestData['dispatch_zip_code'] = zipCode;
    requestData['phone'] = contactNumber;
    requestData['cell_phone'] = cellPhone;
    requestData['email'] = email;
    requestData['tax_id'] = textID;
    requestData['notes'] = note;
    requestData['dispatch_shipping_notes'] = note;
    requestData['group_id'] = selectedRole;
    requestData['discount'] = "0";
    requestData['term_id'] = selectedPaymentCondition;
    return await post('addCustomer', data: requestData);
  }

  Future<dynamic> placeOrder({
    required OrderPlaceRequestBody orderPlaceRequestBody,
  }) async {
    Map<String, dynamic> requestData = {};
    Map<String, dynamic> orderData = orderPlaceRequestBody.toJson();
    orderData.forEach((key, value) {
      if (value is List) {
        requestData[key] = value;
      } else {
        requestData[key] = value.toString();
      }
    });

    if (kDebugMode) {
      print(jsonEncode(requestData));
    }
    return await post('addOrder', data: requestData);
  }

  Future<dynamic> placeCreditOrder({
    required OrderPlaceRequestBody orderPlaceRequestBody,
  }) async {
    Map<String, dynamic> requestData = {};
    Map<String, dynamic> orderData = orderPlaceRequestBody.toJson();
    orderData.forEach((key, value) {
      if (value is List) {
        requestData[key] = value;
      } else {
        requestData[key] = value.toString();
      }
    });

    if (kDebugMode) {
      print(jsonEncode(requestData));
    }
    return await post('addCredit', data: requestData);
  }

  Future<dynamic> checkDBUpdate() async {
    LoginDataModel userProfile = LoginDataModel.instance;
    int companyId = int.parse(userProfile.info?.companyId ?? '0');
    return await post('getDatabaseInfo', data: {
      'company_id': companyId,
      'language_id': userProfile.info?.languageId ?? '1',
    });
  }

  /// Function to update profile
  /// [firstName] is the first name of the user
  /// [lastName] is the last name of the user
  /// [phoneNumber] is the phone number of the user
  ///
  /// Returns a [Future] of [dynamic]
  Future<dynamic> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    LoginDataModel userProfile = LoginDataModel.instance;
    return await post('updateProfile', data: {
      'user_id': int.tryParse(userProfile.info?.userId ?? '-1') ?? -1,
      // 'language_id': userProfile.info?.languageId ?? '1',
      // 'company_id': userProfile.info?.companyId ?? '3',
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
    });
  }

  /// function to load order details from API
  /// [orderId] is the order id of the order
  Future<dynamic> loadSalesmanOrder({
    required String orderId,
  }) async {
    LoginDataModel userProfile = LoginDataModel.instance;
    return await post('orderDetails', data: {
      'language_id': userProfile.info?.languageId ?? '1',
      'user_id': userProfile.info?.userId ?? '8',
      'company_id': userProfile.info?.companyId ?? '3',
      'order_id': orderId,
    });
  }

  /// warehouse order delivered API call
  /// params [OrderDispatchAPIRequestModel] is the model class for the request
  Future<dynamic> warehouseOrderDelivered({
    required OrderDispatchAPIRequestModel orderDispatchAPIRequestModel,
  }) async {
    // LoginDataModel userProfile = LoginDataModel.instance;
    return await post(
      'updateOrderStatus',
      data: orderDispatchAPIRequestModel.toJson(),
    );
  }

  /// function which call the apis for the order history of the warehouse
  /// params [isHistory] is the boolean value which is used to identify the
  ///
  Future<dynamic> loadWarehouseOrderHistory({
    required bool isHistory,
  }) async {
    LoginDataModel userProfile = LoginDataModel.instance;
    String path = isHistory ? 'warehouseOrderList' : 'warehouseOrderReceivedList';
    return await post(path, data: {
      'language_id': userProfile.info?.languageId ?? '1',
      'warehouse_user_id': userProfile.info?.userId ?? '8',
      'company_id': userProfile.info?.companyId ?? '3',
    });
  }

  /// function to load the warehouse order details
  Future<dynamic> loadWareHouseOrderDetails({
    required String? orderId,
  }) async {
    LoginDataModel userProfile = LoginDataModel.instance;
    return await post('warehouseOrderDetails', data: {
      'language_id': userProfile.info?.languageId ?? '1',
      // 'warehouse_user_id': userProfile.info?.userId ?? '8',
      'company_id': userProfile.info?.companyId ?? '3',
      'order_id': orderId,
    });
  }

  /// function to add product to the warehouse order data
  /// params [orderId] is the order id of the order
  /// params [product] is the product of the [ProductDetailsDataModel]
  /// params [quantity] is the quantity of the product
  ///
  /// returns a [Future] of [dynamic]
  Future<dynamic> editWarehouseOrderByAddingProduct({
    required String? orderId,
    required ProductList product,
    required int quantity,
    required WarehouseHistoryDataModel? ordersHistoryDataModel,
  }) async {
    LoginDataModel userProfile = LoginDataModel.instance;
    if (ordersHistoryDataModel == null) {
      List<Map<String, dynamic>>? dataModel =
          await SyncedDB.instance.readWarehouseOrders(orderId: orderId, isHistory: null);
      ordersHistoryDataModel = WarehouseHistoryDataModel.fromJson(dataModel.first);
    }
    return await post('addEditOrder', data: {
      'order_id': orderId,
      'company_id': userProfile.info?.companyId ?? '-1',
      'product_id': product.productId,
      'qty': quantity,
      'sale_price': product.salePrice,
      'discount': ordersHistoryDataModel.discount,
      'discount_type': ordersHistoryDataModel.discountType,
      'comments': product.comment,
    });
  }

  /// api to generate otp for password reset
  /// params [email] is the email of the user
  /// params [usertype]
  Future<dynamic> generateResetOtp(
    String email,
    String usertype,
  ) async {
    return await post(
      'generateOtp',
      data: {'email': email, 'user_type': usertype},
    );
  }

  /// api to reset password
  /// params [otp] is the OTP sent to email
  /// params [email] is the email of the user
  /// params [password] is the new password of the user
  /// params [user_type] is the type of user (Salesman or Warehouse Manager)
  Future<dynamic> resetPassword({
    required String otp,
    required String email,
    required String password,
    required String userType,
  }) async {
    return await post('verifiedOtp', data: {
      'otp': otp,
      'email': email,
      'password': password,
      'user_type': userType,
    });
  }

  /// api to update password
  /// params [oldPassword] is the old password of the user
  /// params [newPassword] is the new password of the user
  Future<dynamic> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    LoginDataModel userProfile = LoginDataModel.instance;
    return await post('changePassword', data: {
      'user_id': userProfile.info?.userId ?? '-1',
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  /// api to get the available languages from the server
  Future<LanguageDataModel?> getLanguages({String? languageId}) async {
    dynamic response = await get('languages', queryParameters: {});
    if (response == null || response is! Map<String, dynamic>) {
      return null;
    }
    return LanguageDataModel.fromJson(response);
  }

  /// api to load warehouse product list
  /// params [categoryId] is the category id of the product
  /// params [search] is the search string
  Future<dynamic> loadWarehouseProductList({
    String? categoryId,
    String? search,
  }) async {
    LoginDataModel userProfile = LoginDataModel.instance;
    Customer? defaultCustomer = defaultCustomerNotifier.value;
    Map<String, dynamic> data = {
      'language_id': userProfile.info?.languageId ?? '1',
      'company_id': userProfile.info?.companyId ?? '3',
      'warehouse_user_id': userProfile.info?.userId ?? '8',
      'customer_id': defaultCustomer?.customerId ?? '-1',
    };
    if (categoryId != null) {
      data['category_id'] = categoryId;
    }
    if (search != null && search.isNotEmpty) {
      data['search'] = search;
    }
    return await post('inventoryList', data: data);
  }

  Future<dynamic> editWarehouseOrderProductDeliverPack({
    required String orderId,
    required ProductList product,
    required String quantity,
    required String pack,
  }) async {
    return await post('updateEditOrder', data: {
      'order_id': orderId,
      'product_id': product.productId,
      'delivered_qty': quantity,
      'delivered_pack': int.tryParse(pack) ?? 0,
    });
  }

  Future<dynamic> warehouseOrderInventoryList() async {
    LoginDataModel userProfile = LoginDataModel.instance;
    return await post('warehouseOrderInventoryList', data: {
      'language_id': userProfile.info?.languageId ?? '1',
      'warehouse_user_id': userProfile.info?.userId ?? '8',
      'company_id': userProfile.info?.companyId ?? '3',
    });
  }

  Future<dynamic> dispatchOrder({required Map<String, dynamic> data}) async {
    return await post('updateInventoryStatus', data: data);
  }

  Future<dynamic> getOrderDetails({required String orderId, required String orderNumber}) async {
    return await post('warehouseDetailsOrderInventoryList', data: {
      'order_id': orderId,
      'order_number': orderNumber,
    });
  }

  Future<dynamic> updateLocationPermissionAndGPSUpdate({
    required bool isHasPermission,
    required bool isGPSOn,
  }) async {
    Map<String, dynamic> data = {};
    LoginDataModel userProfile = LoginDataModel.instance;
    data['user_id'] = userProfile.info?.userId ?? '-1';
    data['company_id'] = userProfile.info?.companyId ?? '-1';
    data['login'] = FullVendorSharedPref.instance.userType;
    data['textinfo'] = 'permission:${isHasPermission ? 'Yes' : 'No'},gps:${isGPSOn ? 'Yes' : 'No'}';
    return await post('gpslog', data: data);
  }

  Future<dynamic> updateLocation({
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime timestamp,
  }) async {
    Map<String, dynamic> data = {};
    LoginDataModel userProfile = LoginDataModel.instance;
    data['user_id'] = userProfile.info?.userId ?? '-1';
    data['company_id'] = userProfile.info?.companyId ?? '-1';
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['login'] = FullVendorSharedPref.instance.userType;
    data['accuracy'] = accuracy;
    data['timestamp'] = timestamp.toIso8601String();
    data['deviceinfo'] = deviceDetails;
    return await post('gpstracker', data: data);
  }

  Future<dynamic> checkDBVersion() async {
    var postData = {
      "deviceinfo": deviceDetails,
      "so": Platform.isIOS ? "IOS" : "Android",
      "versionname": versionName,
      "version": versionCode,
    };
    var response = await post('checkVersion', data: postData);

    if (response is String) {
      response = jsonDecode(response);
    }
    if (response is Map<String, dynamic>) {
      return response;
    }
    if (response is List) {
      return response.firstOrNull;
    }
  }

  Future<dynamic> updateOneVersionFromLastInDbVersion() async {
    // int lastVersion = FullVendorSharedPref.instance.syncDbVersion;
    var postData = {
      "deviceinfo": deviceDetails,
      "so": Platform.isIOS ? "IOS" : "Android",
      "versionname": versionName,
      "version": versionCode,
    };
    return await post("APKUpdateVersion", data: postData);
  }

  /// api to load warehouse product list
}
