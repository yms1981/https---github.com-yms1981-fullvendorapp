import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:FullVendor/db/offline_saved_db.dart';
import 'package:FullVendor/db/shared_pref.dart';
import 'package:FullVendor/utils/extensions.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:workmanager/workmanager.dart';

import '../application/application_global_keys.dart';
import '../model/login_model.dart';
import '../network/apis.dart';
import '../screens/sync/customer_sync_page.dart';
import '../utils/notification/notifications.dart';

class SyncedDB {
  static final SyncedDB instance = SyncedDB._internal();

  factory SyncedDB() => instance;

  SyncedDB._internal();

  Database? _db;

  /// function to open database to perform operations
  /// return: void
  /// throws: Exception if db is not opened
  Future<void> openDB() async {
    if (_db != null && _db!.isOpen) {
      return;
    }
    final Directory directory = await dbDirectory();
    String userId = LoginDataModel.instance.info?.userId ?? '';
    final String dbName = 'gallery_$userId.db';
    _db = await openDatabase(
      '${directory.path}/$dbName',
      version: FullVendorSharedPref.instance.syncDbVersion,
      onOpen: _onDBOpen,
      onCreate: _onDBCreate,
    );
  }

  /// function to close database to release resources and memory
  /// return: void
  /// throws: Exception if db is not closed
  Future<void> closeDatabase() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
    }
  }

  /// function to delete database file from storage
  /// return: void
  /// throws: Exception if db is not deleted
  Future<void> deleteDatabase() async {
    await closeDatabase();
    final Directory directory = await dbDirectory();
    final String path = directory.path;
    String userId = LoginDataModel.instance.info?.userId ?? '';
    final String dbName = 'gallery_$userId.db';
    final File file = File('$path/$dbName');

    /// checking is file exist or not
    /// if not exist then return
    /// else delete the file
    if (!file.existsSync()) {
      return;
    }
    await file.delete();
  }

  /// function to handle the db open action
  Future<void> _onDBOpen(Database db) async {
    if (kDebugMode) {
      print('opened');
    }
  }

  /// function to handle the db create action
  /// this function will be called when db is created
  /// return: void
  Future<void> _onDBCreate(Database db, int version) async {
    if (kDebugMode) {
      print('created');
    }
  }

  /// function to check whether database is downloaded or not and also whether
  /// it is healthy and can perform operations or not
  /// return: true if exist and healthy otherwise false
  Future<bool> isSynced() async {
    if (_db != null && _db!.isOpen) {
      return true;
    }
    bool isExists = await _isDownloadedDBExist();
    if (!isExists) {
      return false;
    }
    bool isHealthy = await _canOpenDatabase();
    return isHealthy;
  }

  /// function to check whether database with respect to the company id exist or not
  /// return: true if exist, false if not exist
  Future<bool> _isDownloadedDBExist() async {
    try {
      final Directory directory = await dbDirectory();
      final String path = directory.path;
      String userId = LoginDataModel.instance.info?.userId ?? '';
      final String dbName = 'gallery_$userId.db';
      final File file = File('$path/$dbName');
      var isExistsSyncs = file.existsSync();
      return isExistsSyncs;
    } catch (e) {
      return false;
    }
  }

  /// function to check whether database can be opened or not
  /// return: true if can be opened other wise false
  /// If database is malformed start download the database
  Future<bool> _canOpenDatabase() async {
    try {
      // Define the path to your database
      String userId = LoginDataModel.instance.info?.userId ?? '';
      final String databasePath = 'gallery_$userId.db';

      // Open the database
      bool? isCreated;
      Database database = await openDatabase(
        databasePath,
        version: FullVendorSharedPref.instance.syncDbVersion,
        onUpgrade: (db, old, newVersion) async {
          //FullVendor.instance.context.showSnackBar('Malformed Database.');
          double downLoadProgress = FullVendor.instance.downloadProgress.value;
          isCreated = downLoadProgress != 100;
          //await downloadDB();
          await downloadDB();
        },
      );

      // Close the database to release resources
      await database.close();
      isCreated ??= false;

      // Return true if the database can be opened
      return !isCreated!;
    } catch (e) {
      // Return false if an error occurs while opening the database
      return false;
    }
  }

  ///   function to download DB from url
  ///   url: url of file
  Future<String?> downloadDB() async {
    String userId = LoginDataModel.instance.info?.userId ?? '';
    final String dbName = 'gallery_$userId.db';
    String companyId = LoginDataModel.instance.info?.companyId ?? '';

    /// if two user with same company id is there then save the file with user id
    /// the file mostly have identical data but save with user id to avoid conflict
    /// done as per request.
    String url = 'http://sync.fullvendor.com/gallery_$companyId.db';
    if (kDebugMode) {
      print(url);
    }
    // String path = "";

    /*SnackBar snackBar = SnackBar(
      duration: const Duration(minutes: 1),
      dismissDirection: DismissDirection.vertical,
      content: ValueListenableBuilder(
        valueListenable: FullVendor.instance.downloadProgress,
        builder: (context, value, child) {
          double progress = FullVendor.instance.downloadProgress.value;
          progress = progress;
          return Text(
            "Syncing progress ${progress.toStringWithoutRounding(2)}%",
          );
        },
      ),
    );*/

    /*FullVendor.instance.scaffoldMessengerKey.currentState
        ?.showSnackBar(snackBar);*/
    if (kDebugMode) {
      print(FullVendor.instance.downloadProgress.value);
    }
    if (FullVendor.instance.downloadProgress.value >= 100) {
      FullVendor.instance.downloadProgress.value = 0;
      return dbName;
    }
    await SyncedDB.instance.closeDatabase();
    if (FullVendor.instance.downloadProgress.value != 0 && syncStatus != SyncStatus.failed) {
      return dbName;
    }
    try {
      var response = await downloadFileDIO(url, saveAs: dbName);
      // update the db version
      var apiResponse = await Apis().updateOneVersionFromLastInDbVersion();
      if (kDebugMode) {
        print(apiResponse);
      }
      return response;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      syncStatus = SyncStatus.failed;
      String message = (e as DioException).message ?? 'Failed to download database';
      FullVendor.instance.dbUpdateLogMessage.value = message;
      FullVendor.instance.downloadProgress.value = 0;
      rethrow;
    }
    // return path;
  }

  Future<dynamic> startMicroUpdate() async {
    await startMicroUpdates();
    String taskName = "startMicroUpdate";
    await Workmanager().cancelByUniqueName(taskName);
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      inputData: {},
      frequency: const Duration(hours: 1),
      initialDelay: const Duration(hours: 1),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  ///   function to download file from url with stream progress
  ///   url: url of file
  ///   saveAs: name of file to save
  ///   return: path of downloaded file
  ///   throws: Exception if file is not downloaded
  Future<String> downloadFileDIO(String url, {String? saveAs}) async {
    // Get the download directory
    final Directory directory = await dbDirectory();
    final String path = directory.path;
    final String fileName = saveAs ?? url.split('/').last;
    final savePath = '$path/$fileName';

    final dio = Dio();
    await SyncedDB.instance.closeDatabase();
    await SyncedDB.instance.deleteDatabase();
    var updateLogger = FullVendor.instance.dbUpdateLogMessage;
    updateLogger.value = "Downloading Database...";
    await dio.download(url, savePath, onReceiveProgress: (received, total) {
      if (total != -1) {
        final double progress = (received / total);
        FullVendor.instance.downloadProgress.value = progress * 100;
        var totalInKb = total / 1024;
        double? totalInMB;
        if (totalInKb > 1024) {
          totalInMB = totalInKb / 1024;
        }
        var receivedInKb = received / 1024;
        double? receivedInMB;
        if (receivedInKb > 1024) {
          receivedInMB = receivedInKb / 1024;
        }
        updateLogger.value =
            "${(receivedInMB ?? receivedInKb).toStringAsFixed(2)} ${(receivedInMB != null) ? 'MB' : 'KB'}/${(totalInMB ?? totalInKb).toStringAsFixed(2)} ${(totalInMB != null) ? 'MB' : 'KB'}";
      } else {
        if (kDebugMode) {
          print(received);
        }
      }
    });
    if (kDebugMode) {
      print('Download completed!');
      DateTime now = DateTime.now();
      String lastDownloadedOn = "";
      int date = now.day;
      int month = now.month;
      int year = now.year;

      lastDownloadedOn = "$date/$month/$year";
      FullVendorSharedPref.instance.lastDbUpdateCheck = lastDownloadedOn;
    }
    syncStatus = SyncStatus.completed;
    return savePath;
  }

  /// function to read the customer list from db
  /// return: list of map of <String,dynamic>
  Future<List<Map<String, dynamic>>> readCustomerList({
    String? search,
    String sort = "name",
    String order = "ASC",
    bool showAll = false,
  }) async {
    await openDB();
    // String companyId = LoginDataModel.instance.info?.companyId ?? '';
    String userId = LoginDataModel.instance.info?.userId ?? '';
    String query = "SELECT * FROM customersList";
    if (search != null && search.isNotEmpty) {
      query += " WHERE name LIKE '%$search%'";
    } else {
      query += " WHERE 1=1";
    }
    // todo check for user, weather can operate with all customer or not
    // query += " and company_id = '$companyId'";
    if (!showAll) {
      query +=
          " and (user_id LIKE '$userId,%' OR user_id LIKE '%,$userId,%' OR user_id LIKE '%,$userId')";
    }
    query += " ORDER BY $sort $order";
    List<Map<String, dynamic>> list = await _db!.rawQuery(query);
    return list;
  }

  /// function to load products like with category_id
  /// return: list of map of <String,dynamic>
  Future<List<Map<String, dynamic>>> readProducts({
    String? categoryId,
    String? search,
  }) async {
    await openDB();
    // String companyId = LoginDataModel.instance.info?.companyId ?? '';
    String query = "SELECT * FROM productList";

    if (search != null && search.isNotEmpty) {
      query += " WHERE name like '%$search%' or sku like '%$search%' or "
          "descriptions like '%$search%' or tags like '%$search%' or "
          "barcode like '%$search%'";
    } else {
      if (categoryId != null && categoryId.isNotEmpty) {
        query += " where INSTR(',' || category_id || ',', ',$categoryId,')";
      }
    }
    query += " and status = '1'";
    query += " ORDER BY CAST(FilaOrden AS INTEGER)";
    List<Map<String, dynamic>> list = List.from(await _db!.rawQuery(query));
    List<Map<String, dynamic>> newList = [];
    for (Map<String, dynamic> element in list) {
      List<Map<String, dynamic>> images = await readProductImages(element['product_id']);
      Map<String, dynamic> map = {};
      map.addAll(element);
      map['images'] = images.toList();
      newList.add(map);
    }
    return newList;
  }

  /// function to read product Details from Db based on product id
  /// returns: Map<String,dynamic>
  Future<Map<String, dynamic>> readProductDetails(String productId) async {
    await openDB();
    // String companyId = LoginDataModel.instance.info?.companyId ?? '';
    String query = "SELECT * FROM productList";
    query += " WHERE product_id = '$productId'";
    // query += " and company_id = '$companyId'";
    List<Map<String, dynamic>> list = await _db!.rawQuery(query);
    List<Map<String, dynamic>> images = await readProductImages(list.first['product_id']);
    Map<String, dynamic> map = {};
    map.addAll(list.first);
    map['images'] = images.toList();
    return map;
  }

  /// function to get the count of products based on categoryId
  /// returns: the length/size/count of products
  Future<int> productsCountByCategoryId(String categoryId) async {
    await openDB();
    // String companyId = LoginDataModel.instance.info?.companyId ?? '';
    String query = "SELECT * FROM productList";
    query += " WHERE category_id = '$categoryId'";
    // query += " and company_id = '$companyId'";
    List<Map<String, dynamic>> list = await _db!.rawQuery(query);
    return list.length;
  }

  /// function to read category list from db where product count of category is greater than 0
  /// returns: List<Map<String,dynamic>>
  Future<List<Map<String, dynamic>>> readCategoryList({
    String? search,
    String sort = "order_id",
    String order = "ASC",
  }) async {
    await openDB();
    // String companyId = LoginDataModel.instance.info?.companyId ?? '';
    String query = "SELECT * FROM categoryList";
    if (search != null && search.isNotEmpty) {
      query += "WHERE  category_name LIKE '%$search%'";
    }
    query += " ORDER BY $sort $order";
    List<Map<String, dynamic>> list = await _db!.rawQuery(query);
    List<Map<String, dynamic>> newList = [];
    for (Map<String, dynamic> map in list) {
      int count = await productsCountByCategoryId(map['category_id']);
      if (count > 0) {
        newList.add(map);
      }
    }
    newList.sort(
      (a, b) {
        var orderIdA = int.tryParse(a["order_id"]) ?? 0;
        var orderIdB = int.tryParse(b["order_id"]) ?? 0;
        return orderIdA.compareTo(orderIdB);
      },
    );
    return newList;
  }

  /// function to read product images from table product_images where product_id = productId
  /// returns: List<Map<String,dynamic>>
  Future<List<Map<String, dynamic>>> readProductImages(String productId) async {
    await openDB();
    // String companyId = LoginDataModel.instance.info?.companyId ?? '';
    String query = "SELECT * FROM product_images";
    query += " WHERE product_id = '$productId'";
    // query += " and company_id = '$companyId'";
    List<Map<String, dynamic>> list = await _db!.rawQuery(query);
    return list;
  }

  /// function to get customer details from table:customersList where customer_id = customerId
  /// returns: Map<String,dynamic>
  Future<Map<String, dynamic>> readCustomerDetails(String customerId) async {
    await openDB();
    // String companyId = LoginDataModel.instance.info?.companyId ?? '';
    String query = "SELECT * FROM customersList";
    query += " WHERE customer_id = '$customerId'";
    // query += " and company_id = '$companyId'";
    List<Map<String, dynamic>> list = await _db!.rawQuery(query);
    return list.firstOrNull ?? {};
  }

  /// Function to read odetails from db with respect to order id
  /// returns: List<Map<String,dynamic>>
  /// throws: Exception if db is not opened
  Future<List<Map<String, dynamic>>> loadOrderDetails(String orderId) async {
    await openDB();
    String query = "SELECT * FROM odetailsList";
    query += " WHERE order_id = '$orderId'";
    query += kDebugMode ? " limit 10" : "";
    // query += " and company_id = '$companyId'";
    List<Map<String, dynamic>> list = await _db!.rawQuery(query);
    List<Map<String, dynamic>> newList = [];
    newList.addAll(list);
    return newList;
  }

  /// function to get current order status text based on current order_status
  /// checked with cod_status of table statusOrdersList
  /// returns: Map<String,dynamic>
  /// throws: Exception if db is not opened
  Future<Map<String, dynamic>> orderStatusValue({
    required String orderStatus,
  }) async {
    await openDB();
    String query = "SELECT * FROM statusOrdersList";
    query += " WHERE cod_status = '$orderStatus'";
    // query += " and company_id = '$companyId'";
    List<Map<String, dynamic>> list = await _db!.rawQuery(query);
    return list.first;
  }

  /// function to read the order history list from db for selected customer id
  /// return: list of map of <String,dynamic>
  /// throws: Exception if db is not opened
  Future<List<Map<String, dynamic>>> readOrderHistoryList({
    required String customerId,
    String? orderId,
  }) async {
    await openDB();
    // String companyId = LoginDataModel.instance.info?.companyId ?? '';
    String query =
        "SELECT *, cast ((cast(amount as float) - cast(discount_a as float)) as text) as totalorder FROM ordersList";
    if (orderId != null && orderId.isNotEmpty) {
      query += " WHERE order_id = '$orderId'";
    } else {
      query += " WHERE customer_id = '$customerId'";
    }

    query += ' order by created desc';
    List<Map<String, dynamic>> list = await _db!.rawQuery(query);
    List<Map<String, dynamic>> newList = [];
    for (Map<String, dynamic> map in list) {
      Map<String, dynamic> customerDetails = await readCustomerDetails(map['customer_id']);
      List<Map<String, dynamic>> orderDetails = await loadOrderDetails(map['order_id']);
      Map<String, dynamic> statusValue = await orderStatusValue(orderStatus: map['order_status']);

      Map<String, dynamic> newMap = {};
      Decimal discount = Decimal.tryParse(map['discount'] ?? '0') ?? Decimal.zero;

      /// customer details
      newMap['business_name'] = customerDetails['business_name'];
      newMap['name'] = customerDetails['name'];
      newMap['discount'] = discount.toStringAsPrecision(2);
      newMap['email'] = customerDetails['email'];
      newMap['phone'] = customerDetails['phone'];

      ///order details
      newMap['tipo_d'] = map['tipo_d'];
      newMap['customer_id'] = map['customer_id'];
      newMap['order_id'] = map['order_id'];
      newMap['order_number'] = map['order_number'];
      newMap['order_comments'] = map['order_comments'];
      newMap['created'] = map['created'];
      newMap['discount_type'] = map['discount_type'];
      newMap['updated'] = map['updated'];

      ///order status details
      newMap['name_status_spanish'] = statusValue['name_status_spanish'];
      newMap['name_status_english'] = statusValue['name_status_english'];

      Decimal orderTotal = Decimal.zero;
      Decimal totalDiscountedAmount = Decimal.zero;
      Decimal discountInPercentage = Decimal.zero;
      if (discount > Decimal.zero) {
        discountInPercentage = discount * Decimal.parse("0.01");
      }
      List<Map<String, dynamic>> products = [];
      for (Map<String, dynamic> element in orderDetails) {
        dynamic salePrice = element['sale_price'] ?? 0;
        dynamic quantity = element['qty'] ?? 0;
        if (salePrice is String) {
          salePrice = Decimal.tryParse(salePrice) ?? Decimal.zero;
        }
        if (quantity is String) {
          quantity = Decimal.tryParse(quantity) ?? Decimal.zero;
        }

        Decimal total = salePrice * quantity;
        Decimal discountAmount = total * discountInPercentage;

        totalDiscountedAmount += discountAmount;
        orderTotal += total;
        List<Map<String, dynamic>> images = await readProductImages(element['product_id']);

        Map<String, dynamic> product = {};
        product.addAll(element);
        product['images'] = images.toList();
        products.add(product);
      }

      Decimal totalorden = Decimal.zero;

      totalorden = (Decimal.tryParse(map['totalorder'] ?? '') ?? Decimal.zero);

      ///product details by loop
      newMap['product_list'] = products;
      newMap['totalamount'] =
          (Decimal.tryParse(map['total_amount'] ?? '') ?? Decimal.zero).toStringAsFixed(2);
      newMap['discount_a'] =
          (Decimal.tryParse(map['discount_a'] ?? '') ?? Decimal.zero).toStringAsFixed(2);
      newMap['amount'] = (Decimal.tryParse(map['amount'] ?? '') ?? Decimal.zero).toStringAsFixed(2);
      newMap['ordered_total'] = (totalorden).toStringAsFixed(2);

      /// adding details to list
      newList.add(newMap);
    }

    return newList;
  }

  /// function to get the requestedList from db based on product_id and
  /// customer_id
  /// params: productId, customerId
  /// return: list of map of <String,dynamic>
  ///
  Future<List<Map<String, dynamic>>> loadRequestedListFromDB({
    required String productId,
    required String customerId,
  }) async {
    String query = "SELECT * FROM requestedList WHERE product_id = '$productId' AND "
        "customer_id = '$customerId'";
    await openDB();
    List<Map<String, dynamic>> data = await _db!.rawQuery(query);
    List<Map<String, dynamic>> newList = [];
    newList.addAll(data);
    return newList;
  }

  /// function to read order for warehouse from db with table name warehouseordersList
  /// return: list of map of <String,dynamic>
  ///
  Future<List<Map<String, dynamic>>> readWarehouseOrders({
    String? orderId,
    bool? isHistory = true,
  }) async {
    String? userId = LoginDataModel.instance.info?.userId;
    await openDB();
    String query = "SELECT * FROM warehouseordersList  WHERE "
        "warehouse_user_id = '${userId ?? ''}' ";
    if (isHistory != null) {
      if (isHistory) {
        query += "AND order_status <> 0 and order_status <> 8 and order_status <> 9";
      } else {
        query += "AND order_status = 9";
      }
    }
    if (orderId != null && orderId.isNotEmpty) {
      query += " AND order_id = '$orderId'";
    }
    List<Map<String, dynamic>> list = await _db!.rawQuery(query);
    List<Map<String, dynamic>> newList = [];

    for (var element in list) {
      String customerId = element['customer_id'];
      Map<String, dynamic> customerDetails = await readCustomerDetails(customerId);

      Decimal discount = Decimal.tryParse(customerDetails['discount'] ?? '0') ?? Decimal.zero;

      Map<String, dynamic> orderData = {};

      /// customer details
      orderData['business_name'] = customerDetails['business_name'];
      orderData['name'] = customerDetails['name'];
      orderData['discount'] = discount.toDecimalFormat(fractionDigits: 2);
      orderData['email'] = customerDetails['email'];
      orderData['phone'] = customerDetails['phone'];

      ///order details
      orderData['tipo_d'] = element['tipo_d'];
      orderData['customer_id'] = element['customer_id'];
      orderData['order_id'] = element['order_id'];
      orderData['order_number'] = element['order_number'];
      orderData['order_comments'] = element['order_comments'] ?? "";
      orderData['created'] = element['created'];
      orderData['discount_type'] = element['discount_type'];
      orderData['updated'] = element['updated'];
      orderData['payment_method'] = element['payment_method'];
      orderData['payment_status'] = element['payment_status'];
      orderData['order_status'] = element['order_status'];
      orderData['transaction_id'] = element['transaction_id'];

      ///order status details
      orderData['name_status_spanish'] = element['name_status_spanish'];
      orderData['name_status_english'] = element['name_status_english'];

      /// product list with calculative data for payments and other details
      /// manually load the product details from db
      List<Map<String, dynamic>> orderDetails = await loadOrderDetails(element['order_id']);

      Decimal orderTotal = Decimal.zero;
      Decimal totalDiscountedAmount = Decimal.zero;
      Decimal discountInPercentage = Decimal.zero;
      List<Map<String, dynamic>> products = [];
      Decimal totalQuantity = Decimal.zero;

      if (discount > Decimal.zero) {
        discountInPercentage = discount * Decimal.parse("0.01");
      }
      for (Map<String, dynamic> order in orderDetails) {
        dynamic salePrice = order['sale_price'] ?? Decimal.zero;
        dynamic deliveredQuantity = order['delivered_quantity'] ?? Decimal.zero;
        dynamic quantity = order['qty'] ?? Decimal.zero;
        if (salePrice is String) {
          salePrice = Decimal.tryParse(salePrice) ?? Decimal.zero;
        }
        if (quantity is String) {
          quantity = Decimal.tryParse(quantity) ?? Decimal.zero;
        }

        Decimal total = salePrice * quantity;
        Decimal discountAmount = total * discountInPercentage;

        totalDiscountedAmount += discountAmount;
        orderTotal += total;
        totalQuantity += (quantity ?? Decimal.zero) as Decimal;

        List<Map<String, dynamic>> requestedList = await loadRequestedListFromDB(
          productId: order['product_id'],
          customerId: element['customer_id'],
        );

        List<Map<String, dynamic>> images = await readProductImages(order['product_id']);
        // for (var image in images) {
        //   image['imageBlob'] = [];
        // }

        Map<String, dynamic> product = {};
        product['product_id'] = order['product_id'];
        product['detail_id'] = order['detail_id'];
        product['barcode'] = '';
        product['sku'] = order['sku'];
        product['name'] = order['name'];
        product['sale_price'] = order['sale_price'];
        product['qty'] = (quantity as Decimal).toStringAsFixed(2);
        product['delivered_qty'] = deliveredQuantity.toString();
        product['delivered_pack'] = order['delivered_pack'];
        product['total'] = total.toString();
        product['discount'] = customerDetails['discount'];
        product['discount_type'] = customerDetails['discount_type'];
        product['fob_price'] = order['fob_price'];
        product['comment'] = order['comment'];
        product['currency_type'] = '\$';
        product['created'] = order['created'];
        product['requested'] = requestedList;
        product['images'] = images;
        // add to list
        products.add(product);
      }

      orderData['product_list'] = products;
      orderData['total_quantity'] = totalQuantity.toDecimalFormat();
      orderData['adiscount'] = totalDiscountedAmount.toStringAsFixed(2);
      orderData['ordered_total'] = orderTotal.toDecimalFormat();
      orderData['totalamount'] = (orderTotal - totalDiscountedAmount).toDecimalFormat();

      newList.add(orderData);
    }
    return newList;
  }

  ///function to get the database version from dbb table syncInfo
  /// return: Map<String,dynamic>
  Future<Map<String, dynamic>> getSyncInfo() async {
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('yyMMdd');
    DateTime yesterday = now.subtract(const Duration(days: 1));

    String formattedDate = formatter.format(yesterday);

    List<Map<String, dynamic>> list1 = [];
    list1.add({'id': 1, 'fecha': DateTime.now().toIso8601String(), 'version': formattedDate});

    await openDB();
    List<Map<String, dynamic>> list = await _db!.rawQuery("SELECT * FROM syncInfo");
    await closeDatabase();

    return list.firstOrNull ?? {'id': 1, 'fecha': DateTime.now, 'version': formattedDate};
  }

  /// function to insert order to odetailsList table
  /// params: orderId, productId, quantity
  Future<void> insertWarehouseOrder({
    required String orderId,
    required String productId,
    required int quantity,
    required int packs,
    String? comment,
  }) async {
    await openDB();
    Map<String, dynamic> productDetails = await readProductDetails(productId);
    // int count = (await _db!.query('odetailsList')).length;
    await _db!.insert(
      'odetailsList',
      {
        'detail_id': 0,
        'order_id': orderId,
        'product_id': productId,
        'sku': productDetails['sku'],
        'name': productDetails['name'],
        'qty': quantity,
        'delivered_quantity': quantity,
        'delivered_pack': packs,
        'discount': "0",
        'discount_type': "1",
        'sale_price': productDetails['sale_price'],
        'fob_price': productDetails['fob_price'],
        'purchase_price': productDetails['purchase_price'],
        'comment': comment ?? "",
      },
      // conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // /// function to update quantity of items to odetailsList table
  // /// params: orderId, productId, quantity
  // Future<void> updateOrInsertWarehouseOrder({
  //   required String orderId,
  //   required String productId,
  //   required int quantity,
  //   String? comment,
  // }) async {
  //   await openDB();
  //   int updatedRow = await _db!.update(
  //     'odetailsList',
  //     {'qty': quantity},
  //     where: 'order_id = ? AND product_id = ?',
  //     whereArgs: [orderId, productId],
  //   );
  //   if (updatedRow == 0) {
  //     await insertWarehouseOrder(
  //       orderId: orderId,
  //       productId: productId,
  //       quantity: quantity,
  //       comment: comment,
  //     );
  //   }
  //   await OfflineSavedDB.instance.updateOrInsert(
  //       orderId: orderId, productId: productId, quantity: quantity, pack: 0);
  // }

  /// function to update quantity and packs of items to odetailsList table
  /// params: orderId, productId, quantity
  Future<void> updateOrInsertProductToWareHouseOrder({
    required String orderId,
    required String productId,
    required int quantity,
    required int packs,
    String? comment,
  }) async {
    await openDB();
    int updatedRow = await _db!.update(
      'odetailsList',
      {'delivered_quantity': quantity, 'delivered_pack': packs},
      where: 'order_id = ? AND product_id = ?',
      whereArgs: [orderId, productId],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (updatedRow == 0) {
      await insertWarehouseOrder(
        orderId: orderId,
        productId: productId,
        quantity: quantity,
        comment: comment,
        packs: packs,
      );
    }
    if (updatedRow == 0) {
      await OfflineSavedDB.instance.updateOrInsert(
        orderId: orderId,
        productId: productId,
        quantity: quantity,
        pack: packs,
      );
    } else {
      await OfflineSavedDB.instance.insertOrUpdateEditRecord(
        orderId: orderId,
        productId: productId,
        quantity: quantity,
        pack: packs,
      );
    }
  }

  /// function to load all inventory orders from db
  Future<dynamic> warehouseOrderInventoryList() async {
    await openDB();
    String whereCause =
        "warehouse_user_id = ? AND tipo_d = 'I' AND (order_status = 2 OR order_status = 16)";
    List<String> whereArgs = [LoginDataModel.instance.info?.userId ?? ''];
    List<dynamic> orderData =
        await _db!.query('warehouseordersList', where: whereCause, whereArgs: whereArgs);
    List<Map<String, dynamic>> orderList = [];
    for (var element in orderData) {
      String customerId = element['customer_id'];
      Map<String, dynamic> customerDetails = await readCustomerDetails(customerId);
      Decimal discount = Decimal.tryParse(customerDetails['discount'] ?? '0') ?? Decimal.zero;

      Map<String, dynamic> subData = {};
      subData['business_name'] = customerDetails['business_name'];
      subData['name'] = customerDetails['name'];
      subData['discount'] = discount.toDecimalFormat(fractionDigits: 2);
      subData['email'] = customerDetails['email'];
      subData['phone'] = customerDetails['phone'];

      subData.addAll(element);
      orderList.add(subData);
    }
    return orderList;
  }

  /// function to load inventory order details from db
  /// [orderId] is the order id of the order
  /// return: Future<Map<String,dynamic>?>
  Future<Map<String, dynamic>?> loadInventoryOrderDetails(String orderId) async {
    await openDB();
    String whereCause = "order_id = ?";
    List<String> whereArgs = [orderId];
    List<Map<String, dynamic>> orderData =
        await _db!.query('warehouseordersList', where: whereCause, whereArgs: whereArgs);
    if (orderData.isEmpty) {
      return null;
    }
    Map<String, dynamic> order = orderData.first;
    String customerId = order['customer_id'];
    Map<String, dynamic> customerDetails = await readCustomerDetails(customerId);
    Decimal discount = Decimal.tryParse(customerDetails['discount'] ?? '0') ?? Decimal.zero;

    Map<String, dynamic> subData = {};
    subData['business_name'] = customerDetails['business_name'];
    subData['name'] = customerDetails['name'];
    subData['discount'] = discount.toDecimalFormat(fractionDigits: 2);
    subData['email'] = customerDetails['email'];
    subData['phone'] = customerDetails['phone'];

    // Decimal orderTotal = Decimal.zero;
    // Decimal totalDiscountedAmount = Decimal.zero;
    // Decimal discountInPercentage = Decimal.zero;
    List<Map<String, dynamic>> orderDetails = await loadOrderDetails(orderId);
    List<Map<String, dynamic>> products = [];
    for (Map<String, dynamic> element in orderDetails) {
      dynamic salePrice = element['sale_price'] ?? 0;
      dynamic quantity = element['qty'] ?? 0;
      if (salePrice is String) {
        salePrice = Decimal.tryParse(salePrice) ?? Decimal.zero;
      }
      if (quantity is String) {
        quantity = Decimal.tryParse(quantity) ?? Decimal.zero;
      }

      List<Map<String, dynamic>> images = await readProductImages(element['product_id']);

      Map<String, dynamic> product = {};
      product.addAll(element);
      product['images'] = images.toList();
      products.add(product);
    }

    subData['product_list'] = products;
    subData.addAll(order);

    return subData;
  }

  Future<dynamic> updateOrInsertWarehouseOrder(
      {required String orderId, required String orderStatus}) async {
    await openDB();
    int updatedRow = await _db!.update(
      'warehouseordersList',
      {'order_status': orderStatus},
      where: 'order_id = ?',
      whereArgs: [orderId],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return updatedRow;
  }

  /// function to dispatch inventory order
  /// [orderId] is the order id of the order
  Future<void> dispatchInventoryOrder(String orderId) async {
    await openDB();
    await _db!.update(
      'warehouseordersList',
      {'order_status': 11},
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }
}

/// function to apply the micro updates.
/// By micro updates we mean the updates which are done on the existing data
Future<dynamic> startMicroUpdates() async {
  await FullVendorSharedPref.instance.init();
  var count = await OfflineSavedDB.instance.offlineChangeSetCount();
  if (count > 0) {
    return;
  }
  // BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
  try {
    await NotificationHelper.initialize();
  } catch (e) {
    print(e);
  }
  var downloadProgress = FullVendor.instance.downloadProgress;
  var imageSyncProgress = FullVendor.instance.imageSyncProgress;
  if (!downloadProgress.hasListeners) {
    NotificationHelper.showProgressNotification(
        progressNotifier: downloadProgress, notificationId: 3);
  }
  if (!imageSyncProgress.hasListeners) {
    NotificationHelper.showProgressNotification(
      title: "Image Sync",
      progressNotifier: imageSyncProgress,
      notificationId: 2,
    );
  }
  var _db = SyncedDB.instance._db;
  if (_db == null || !_db.isOpen) {
    await SyncedDB.instance.openDB();
    _db = SyncedDB.instance._db;
  }
  if (_db == null) return;
  double lastProgress = FullVendor.instance.downloadProgress.value;
  FullVendor.instance.downloadProgress.value = 0;
  if (lastProgress > 0.0 && lastProgress < 100) {
    print("update Already in progress");
    return;
  }

  Map<String, String> tableAndMap = {};
  tableAndMap['categoryList'] = 'categoriesList';
  tableAndMap['customersList'] = 'customersList';
  tableAndMap['odetailsList'] = 'wodetailsList';
  tableAndMap['ordersList'] = 'ordersList';
  tableAndMap['warehouseordersList'] = 'warehouseordersList';
  tableAndMap['customergroupsList'] = 'customergroupsList';
  tableAndMap['termList'] = 'termofsaleslist';
  tableAndMap['requestedList'] = 'requestedList';
  tableAndMap['productList'] = 'wproductList';
  // tableAndMap['product_images'] = 'productimageslist';

  String companyId = LoginDataModel.instance.info?.companyId ?? '';
  String languageId = LoginDataModel.instance.info?.languageId ?? '1';
  var postData = {'company_id': companyId, 'language_id': languageId};

  var listOfMap = tableAndMap.entries.toList();
  double progress = 0.0;
  // extra one for product image sync
  int progressAllowed = 100 ~/ (tableAndMap.length + 1);
  FullVendor.instance.downloadProgress.value = progress;
  // await _db.transaction((txn) async {});
  ValueNotifier<String> updateLogger = FullVendor.instance.dbUpdateLogMessage;

  for (var element in listOfMap) {
    String table = element.key;
    String apiEndPoint = element.value;

    dynamic response;
    updateLogger.value = "Getting data from api for table $table.";
    try {
      response = await Apis().post(apiEndPoint, data: postData);
    } catch (e) {
      print(e);
      updateLogger.value = "Getting data from api for table $table failed.";
    }
    updateLogger.value = "Getting data from api for table $table done.";
    if (response == null) continue;
    if (response is String) {
      try {
        response = jsonDecode(response);
      } catch (_) {
        updateLogger.value = "Invalid json for $table";
      }
    }
    if (response is List) {
      dynamic map = {"list": response};
      response = map;
    }
    var dataList = response['list'];
    await SyncedDB.instance.openDB();
    _db = SyncedDB.instance._db;
    var tmpData = (await _db!.query(table, limit: 1)).firstOrNull;
    bool isHasBlob = false;
    List<String> columns = [];

    if (tmpData != null) {
      columns = tmpData.keys.toList();
      isHasBlob = columns.contains('imageBlob');
      if (!isHasBlob) {
        await _db.delete(table);
      }
    }
    int index = 0;
    int length = dataList.length;
    double childIndexProgress = progressAllowed / length;

    await SyncedDB.instance.openDB();
    _db = SyncedDB.instance._db;
    await _db?.transaction((txn) async {
      for (var element in dataList) {
        Map<String, dynamic> map = {};
        if (columns.isNotEmpty) {
          for (String key in element.keys) {
            if (columns.contains(key)) {
              map[key] = element[key];
            }
          }
        } else {
          map = element;
        }
        try {
          int affectedRow = 0;
          if (isHasBlob) {
            affectedRow = await txn.update(
              table,
              map,
              where: 'cat_id = ?',
              whereArgs: [map['cat_id']],
            );
          }
          if (affectedRow != 1) {
            await txn.insert(
              table,
              map,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            updateLogger.value = "Updated/Inserted $table at $index/$length.";
          }
        } catch (e) {
          print(e);
          print('error inserting $table at $index');
          updateLogger.value = "Error inserting $table at $index";
        } finally {
          index++;
        }
        progress += childIndexProgress;
        FullVendor.instance.downloadProgress.value = progress;
      }
    });
  }
  await _startImageMicroUpdates();
  _db?.close();
  FullVendor.instance.downloadProgress.value = 100;
  FullVendorSharedPref.instance.lastMicroUpdatedOn = DateTime.now().millisecondsSinceEpoch;
}

/// function to apply micro updates to the sync database on product_images table
/// return: Future<void>
Future<void> _startImageMicroUpdates() async {
  var tableName = 'product_images';
  var apiEndPoint = 'syncimagesList';
  String companyId = LoginDataModel.instance.info?.companyId ?? '';
  String languageId = LoginDataModel.instance.info?.languageId ?? '1';
  var postData = {'company_id': companyId, 'language_id': languageId};
  dynamic response;
  var updateLogger = FullVendor.instance.dbUpdateLogMessage;
  try {
    updateLogger.value = "Getting data from api for table $tableName.";
    response = await Apis().post(apiEndPoint, data: postData);
  } catch (e) {
    print(e);
    updateLogger.value = "Getting data from api for table $tableName failed.";
  }
  updateLogger.value = "Getting data from api for table $tableName done.";
  if (response == null) return;
  if (response is String) {
    try {
      response = jsonDecode(response);
    } catch (_) {
      updateLogger.value = "Invalid json for $tableName";
    }
  }
  if (response is List) {
    dynamic map = {"list": response};
    response = map;
  }
  var dataList = response['list'] as List<dynamic>;
  await SyncedDB.instance.openDB();
  var db = SyncedDB.instance._db;
  List<Map<String, dynamic>> list = await SyncedDB.instance._db!.query(tableName, limit: 1);
  List<String> columns = [];
  if (list.isNotEmpty) {
    columns = list.first.keys.toList();
  }
  int index = 0;
  int length = dataList.length;
  int progressAllowed = 100 ~/ 1;
  double progressPerIndex = progressAllowed / length;
  double progress = 0.0;
  FullVendor.instance.imageSyncProgress.value = 0;
  for (var element in dataList) {
    // select with product_id
    String? productId = element['product_id'];
    String? imgId = element['img_id'];
    Map<String, dynamic>? map = (await db!.query(
      tableName,
      columns: ['FileSize'],
      where: 'product_id = ? and image_id = ?',
      whereArgs: [productId, imgId],
    ))
        .firstOrNull;
    String? fileSize = element['FileSize']?.toString();
    String? originalFileSize = map?['FileSize']?.toString();
    bool needUpdate = false;
    if (map == null) {
      needUpdate = true;
      Map<String, dynamic> insertData = {};
      for (var column in columns) {
        if (column.contains('blob')) continue;
        insertData[column] = element[column];
      }
      db.insert(tableName, insertData);
    } else if (fileSize != originalFileSize) {
      needUpdate = true;
    }
    if (needUpdate) {
      updateLogger.value = "Downloading image $index of $length.";
      String url = element['url'] ?? '';
      try {
        var response = await Dio().get(url, options: Options(responseType: ResponseType.bytes));
        int updatedRow = await db.update(
          tableName,
          {'imageBlob': response.data, 'FileSize': fileSize},
          where: 'product_id = ? and image_id = ?',
          whereArgs: [productId, imgId],
        );
        print('updated $updatedRow row at index $index');
        updateLogger.value = "Updated image $index of $length.";
      } catch (e) {
        print(e);
        print('error updating $tableName at $index');
        updateLogger.value = "Error updating $tableName at $index";
        rethrow;
      }
    } else {
      updateLogger.value = "Image $index of $length already updated.";
    }

    index++;
    progress += progressPerIndex;
    FullVendor.instance.imageSyncProgress.value = progress;
  }
  FullVendor.instance.imageSyncProgress.value = 100;
}
