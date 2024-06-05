import 'dart:convert';

import 'package:FullVendor/model/login_model.dart';
import 'package:sqflite/sqflite.dart';

import '../model/offline_location_data_model.dart';
import '../model/place_order_model.dart';

/// table for offline salesman order/credit note order
/// table name: OfflineOrderData
String offlineOrderDataTable = "OfflineOrderData";
String _offlineOrderDataTableQuery =
    "create table if not exists $offlineOrderDataTable(order_id INTEGER PRIMARY KEY AUTOINCREMENT,orderMode text,orderCreateTime integer,orderData text)";

/// table for warehouse offline order edit
/// table name: OfflineEditRecord
String offlineEditRecordTable = "OfflineEditRecord";
String _offlineEditRecordTableQuery =
    "create table if not exists $offlineEditRecordTable (id INTEGER PRIMARY KEY AUTOINCREMENT, order_id TEXT, product_id TEXT, quantity integer, pack integer)";

/// table for warehouse new added products
/// table name: OfflineAddedProducts
String offlineAddedProductsTable = "OfflineAddedProducts";
//  , pack integer, discount TEXT, discount_type TEXT
String _offlineAddedProductsTableQuery =
    "create table if not exists $offlineAddedProductsTable (id INTEGER PRIMARY KEY AUTOINCREMENT, order_id TEXT, product_id TEXT, quantity integer)";

/// table for warehouse inventory order qty
/// table name: OfflineInventoryOrderQty
String offlineInventoryOrderQtyTable = "OfflineInventoryOrderQty";
String _offlineInventoryOrderQtyTableQuery =
    "create table if not exists $offlineInventoryOrderQtyTable (id INTEGER PRIMARY KEY AUTOINCREMENT, order_id TEXT, product_id TEXT, quantity integer,pack integer)";

/// table to store the location data of salesman for offline
/// table name: OfflineLocationData
String offlineLocationDataTable = "OfflineLocationData";
String _offlineLocationDataTableQuery =
    "create table if not exists $offlineLocationDataTable ("
    "id INTEGER PRIMARY KEY AUTOINCREMENT, "
    "isLocationAllowed integer, "
    "isGPSOn integer, "
    "latitude REAL, "
    "longitude REAL, "
    "time integer, "
    "accuracy REAL)";

/// table to store login details of the user.
/// table name: OfflineLoginDetails
String offlineLoginDetailsTable = "OfflineLoginDetails";
String _offlineLoginDetailsTableQuery =
    "create table if not exists $offlineLoginDetailsTable ("
    "id INTEGER PRIMARY KEY AUTOINCREMENT, "
    "email TEXT, "
    "password TEXT, "
    "userType TEXT, "
    "sessionData TEXT,"
    "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
    "UNIQUE(email, userType) ON CONFLICT REPLACE"
    ")";

/// table to store the offline updates of order status
/// table name: OfflineOrderStatusUpdateTrack
String offlineOrderStatusUpdateTrackTable = "OfflineOrderStatusUpdateTrack";
String _offlineOrderStatusUpdateTrackTableQuery =
    "create table if not exists $offlineOrderStatusUpdateTrackTable ("
    "id INTEGER PRIMARY KEY AUTOINCREMENT, "
    "order_id TEXT, "
    "order_type TEXT"
    ")";

/// table for manage the inventory dispatch when user is offline
/// table name: OfflineInventoryDispatch
String offlineInventoryDispatchTable = "OfflineInventoryDispatch";
String _offlineInventoryDispatchTableQuery =
    "create table if not exists $offlineInventoryDispatchTable ("
    "id INTEGER PRIMARY KEY AUTOINCREMENT, "
    "order_id TEXT,"
    "order_number TEXT,"
    "data TEXT,"
    "UNIQUE(order_id) ON CONFLICT REPLACE"
    ")";

class OfflineSavedDB {
  static final OfflineSavedDB _instance = OfflineSavedDB._internal();
  static const String _dbName = 'OfflineSavedDB.db';
  static const int _dbVersion = 9;

  factory OfflineSavedDB() => _instance;

  Database? _db;

  OfflineSavedDB._internal();

  static OfflineSavedDB get instance => _instance;

  Future<void> open() async {
    if (_db != null && _db!.isOpen) {
      return;
    }
    _db = await openDatabase(
      _dbName,
      version: _dbVersion,
      onCreate: _onDatabaseCreate,
      onOpen: _onDatabaseOpen,
      onUpgrade: onUpgrade,
    );
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
    }
  }

  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    // calling this same because no change in the table
    // drop all table, done during development process
    await db.execute("DROP TABLE IF EXISTS $offlineOrderDataTable");
    await db.execute("DROP TABLE IF EXISTS $offlineEditRecordTable");
    await db.execute("DROP TABLE IF EXISTS $offlineAddedProductsTable");
    await db.execute("DROP TABLE IF EXISTS $offlineInventoryOrderQtyTable");
    await db.execute("DROP TABLE IF EXISTS $offlineLocationDataTable");
    await db.execute("DROP TABLE IF EXISTS $offlineLoginDetailsTable");
    await db
        .execute("DROP TABLE IF EXISTS $offlineOrderStatusUpdateTrackTable");
    await db.execute("DROP TABLE IF EXISTS $offlineInventoryDispatchTable");
    // create all table again
    await _onDatabaseCreate(db, newVersion);
  }

  Future<void> _onDatabaseCreate(Database db, int version) async {
    await db.execute(_offlineOrderDataTableQuery);
    await db.execute(_offlineEditRecordTableQuery);
    await db.execute(_offlineAddedProductsTableQuery);
    await db.execute(_offlineInventoryOrderQtyTableQuery);
    await db.execute(_offlineLocationDataTableQuery);
    await db.execute(_offlineLoginDetailsTableQuery);
    await db.execute(_offlineOrderStatusUpdateTrackTableQuery);
    await db.execute(_offlineInventoryDispatchTableQuery);
  }

  Future<void> _onDatabaseOpen(Database db) async {}

  Future<void> insert(String orderId, String productId, int quantity) async {
    await _db!.insert(
      offlineAddedProductsTable,
      {
        'order_id': orderId,
        'product_id': productId,
        'quantity': quantity,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Future function too update or insert the quantity of the product in the
  /// database
  /// params [orderId] and [productId] are used to identify the product
  /// params [quantity] is the new quantity of the product
  /// returns [Future<void>]
  ///
  Future<void> updateOrInsert({
    required String orderId,
    required String productId,
    required int quantity,
    required int pack,
  }) async {
    int updatedRow = await _db!.update(
      offlineAddedProductsTable,
      {'quantity': quantity},
      where: 'order_id = ? AND product_id = ?',
      whereArgs: [orderId, productId],
    );
    if (updatedRow == 0) {
      await insert(orderId, productId, quantity);
    }
  }

  /// function to store edit record of warehouse order
  /// params [orderId] is the order id
  /// params [productId] is the product id
  /// params [quantity] is the quantity of the product
  /// params [pack] is the pack of the product
  /// returns [Future<void>]
  Future<void> insertOrUpdateEditRecord({
    required String orderId,
    required String productId,
    required int quantity,
    required int pack,
  }) async {
    var dataMap = {
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'pack': pack
    };
    var affectedRow = await _db!.update(
      offlineEditRecordTable,
      dataMap,
      where: 'order_id = ? AND product_id = ?',
      whereArgs: [orderId, productId],
    );
    if (affectedRow > 0) return;
    await _db!.insert(
      offlineEditRecordTable,
      dataMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Function to save data in the offline order table
  /// params [orderPlaceRequestBody] is the order data
  /// returns [Future<void>]
  Future<void> saveOfflineOrder(
      OrderPlaceRequestBody orderPlaceRequestBody) async {
    dynamic orderData = orderPlaceRequestBody.toJson();
    orderData = jsonEncode(orderData);

    await _db!.insert(
      offlineOrderDataTable,
      {
        'orderMode': orderPlaceRequestBody.tipod,
        'orderCreateTime': DateTime.now().millisecondsSinceEpoch,
        'orderData': orderData,
      },
    );
  }

  /// function to get the offline order data from the table of OfflineOrderData
  /// returns [Future<List<Map<String, dynamic>>>]
  /// returns the list of the offline order data
  Future<List<Map<String, dynamic>>> getOfflineOrderData() async {
    List<Map<String, dynamic>> consulta =
        await _db!.query(offlineOrderDataTable);
    return consulta;
  }

  /// Future function to get the offline change set from the table of
  /// OfflineSavedDB
  /// returns [Future<int>]
  /// returns the count of the offline change set
  Future<int> offlineChangeSetCount() async {
    int changesCount = 0;
    var offlineOrderDataTableData = await _db!.query(offlineOrderDataTable);
    changesCount += offlineOrderDataTableData.length;
    var offlineEditRecordTableData =
        await _db!.query(offlineEditRecordTable, groupBy: 'order_id');
    changesCount += offlineEditRecordTableData.length;
    var offlineAddedProductsTableData =
        await _db!.query(offlineAddedProductsTable, groupBy: 'order_id');
    changesCount += offlineAddedProductsTableData.length;
    var offlineOrderStatusUpdateTrackTableData = await _db!
        .query(offlineOrderStatusUpdateTrackTable, groupBy: 'order_id');
    changesCount += offlineOrderStatusUpdateTrackTableData.length;
    var inventory = await _db!.query(offlineInventoryDispatchTable);
    changesCount += inventory.length;
    return changesCount;
  }

  /// function to delete offline saved order
  /// from the order id
  /// params [offlineOrderId] is the id of the offline order
  /// returns [Future<void>]
  Future<void> deleteOfflineOrder(int offlineOrderId) async {
    await _db!.delete(
      offlineOrderDataTable,
      where: 'order_id = ?',
      whereArgs: [offlineOrderId],
    );
  }

  /// Future function to get the offline order data from the table of OfflineOrderData
  /// return list of order ids modified
  Future<List<String>> getOfflineOrderModificationsIds() async {
    List<Map<String, dynamic>> offlineOrderData = await _db!.query(
      offlineEditRecordTable,
      groupBy: 'order_id',
      columns: ['order_id'],
    );
    List<String> orderIds = [];
    for (var element in offlineOrderData) {
      orderIds.add(element['order_id']);
    }
    offlineOrderData = await _db!.query(
      offlineAddedProductsTable,
      groupBy: 'order_id',
      columns: ['order_id'],
    );
    for (var element in offlineOrderData) {
      if (!orderIds.contains(element['order_id'])) {
        orderIds.add(element['order_id']);
      }
    }
    offlineOrderData = await _db!.query(
      offlineOrderStatusUpdateTrackTable,
      groupBy: 'order_id',
      columns: ['order_id'],
    );
    for (var element in offlineOrderData) {
      if (!orderIds.contains(element['order_id'])) {
        orderIds.add(element['order_id']);
      }
    }
    return orderIds;
  }

  /// Function to delete the change set group by order id from table OfflineOrderData
  Future<void> deleteOfflineOrderChangeSet(String id) async {
    String whereCause = 'order_id = ?';
    List<String> arg = [id];
    List<String> tables = [];
    tables.add(offlineOrderDataTable);
    tables.add(offlineEditRecordTable);
    tables.add(offlineAddedProductsTable);
    tables.add(offlineOrderStatusUpdateTrackTable);

    for (var element in tables) {
      await _db!.delete(element, where: whereCause, whereArgs: arg);
    }
  }

  Future<bool> isEditRecord(String orderID, String productID) async {
    var data = await _db!.query(offlineEditRecordTable,
        where: 'order_id = ? AND product_id = ?',
        whereArgs: [orderID, productID]);
    return data.isNotEmpty;
  }

  Future<List<String>> getEditedProductIds(String orderID) async {
    List<String> productIds = [];
    var data = await _db!.query(offlineEditRecordTable,
        where: 'order_id = ?', whereArgs: [orderID]);
    for (var element in data) {
      String? productId = element['product_id'] as String?;
      if (productId != null) {
        productIds.add(productId);
      }
    }
    return productIds;
  }

  Future<List<String>> getAddedProductIds(String orderID) async {
    List<String> productIds = [];
    var data = await _db!.query(offlineAddedProductsTable,
        where: 'order_id = ?', whereArgs: [orderID]);
    for (var element in data) {
      String? productId = element['product_id'] as String?;
      if (productId != null) {
        productIds.add(productId);
      }
    }
    return productIds;
  }

  Future<void> deleteAddedRecordFor(String orderId, String productID) async {
    await _db!.delete(
      offlineAddedProductsTable,
      where: 'order_id = ? AND product_id = ?',
      whereArgs: [orderId, productID],
    );
  }

  Future<void> deleteOfflineEditRecord(String orderId, String productId) async {
    await _db!.delete(
      offlineEditRecordTable,
      where: 'order_id = ? AND product_id = ?',
      whereArgs: [orderId, productId],
    );
  }

  /// insert or update inventory product qty and packs
  /// params [orderId] is the order id
  /// params [productId] is the product id
  /// params [quantity] is the quantity of the product
  /// params [pack] is the pack of the product
  Future<void> insertOrUpdateInventoryOrderQty({
    required String orderId,
    required String productId,
    required int quantity,
    required int pack,
  }) async {
    var dataMap = {
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'pack': pack
    };
    var affectedRow = await _db!.update(
      offlineInventoryOrderQtyTable,
      dataMap,
      where: 'order_id = ? AND product_id = ?',
      whereArgs: [orderId, productId],
    );
    if (affectedRow > 0) return;
    await _db!.insert(
      offlineInventoryOrderQtyTable,
      dataMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int?> qtyForInventory(String orderId, String productID) async {
    List<Map<String, dynamic>> data = await _db!.query(
      offlineInventoryOrderQtyTable,
      columns: ['quantity'],
      where: 'order_id = ? AND product_id = ?',
      whereArgs: [orderId, productID],
    );
    if (data.isEmpty) return null;
    return data[0]['quantity'] as int?;
  }

  Future<int?> packForInventory(String orderId, String productID) async {
    List<Map<String, dynamic>> data = await _db!.query(
      offlineInventoryOrderQtyTable,
      columns: ['pack'],
      where: 'order_id = ? AND product_id = ?',
      whereArgs: [orderId, productID],
    );
    if (data.isEmpty) return null;
    return data[0]['pack'] as int?;
  }

  Future<void> clearInventoryOrder(String orderId) async {
    await _db!.delete(
      offlineInventoryOrderQtyTable,
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  Future<void> insertLocationData({
    required bool isLocationAllowed,
    required bool isGPSOn,
    required double latitude,
    required double longitude,
    required int time,
    required double accuracy,
  }) async {
    await _db!.insert(
      offlineLocationDataTable,
      {
        'isLocationAllowed': isLocationAllowed ? 1 : 0,
        'isGPSOn': isGPSOn ? 1 : 0,
        'latitude': latitude,
        'longitude': longitude,
        'time': time,
        'accuracy': accuracy,
      },
    );
  }

  Future<List<OfflineLocationData>> getOfflineLocations() async {
    List<Map<String, dynamic>> data =
        await _db!.query(offlineLocationDataTable);
    List<OfflineLocationData> locations = [];
    for (var element in data) {
      locations.add(OfflineLocationData.fromJson(element));
    }
    return locations;
  }

  Future<void> deleteOfflineLocationData(int id) async {
    await _db!.delete(
      offlineLocationDataTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<String>> getInventoryOrderIds({required String orderID}) async {
    List<String> productIds = [];
    var data = await _db!.query(offlineInventoryOrderQtyTable,
        where: 'order_id = ?', whereArgs: [orderID]);
    for (var element in data) {
      String? productId = element['product_id'] as String?;
      if (productId != null) {
        productIds.add(productId);
      }
    }
    return productIds;
  }

  Future<dynamic> offlineLogin({
    required String username,
    required String password,
    required String loginType,
  }) async {
    int time = DateTime.now().millisecondsSinceEpoch;
    // must in in last 7 days
    int offlineLoginTime = time - 604800000;
    List<Map<String, dynamic>> data = await _db!.query(
      offlineLoginDetailsTable,
      where: 'email = ? AND password = ? AND userType = ? AND updated_at > ?',
      whereArgs: [username, password, loginType, offlineLoginTime],
    );
    if (data.isEmpty) {
      return null;
    }
    String sessionDataString = data[0]['sessionData'];
    dynamic sessionData = jsonDecode(sessionDataString);
    return sessionData;
  }

  Future<void> saveOfflineLoginData({
    required String email,
    required String password,
    required String userType,
    required LoginDataModel sessionData,
  }) async {
    String sessionDataString = jsonEncode(sessionData.toJson());
    int time = DateTime.now().millisecondsSinceEpoch;
    await _db!.insert(
      offlineLoginDetailsTable,
      {
        'email': email,
        'password': password,
        'userType': userType,
        'sessionData': sessionDataString,
        'updated_at': time,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteOfflineLoginData(String email, String password) async {
    await _db!.delete(
      offlineLoginDetailsTable,
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
  }

  Future<void> insertOrderStatusUpdateTrack(
      String orderId, String orderType) async {
    await _db!.insert(
      offlineOrderStatusUpdateTrackTable,
      {
        'order_id': orderId,
        'order_type': orderType,
      },
    );
  }

  Future<bool> isOrderStatusUpdateTrack(
      String orderId, String orderType) async {
    List<Map<String, dynamic>> data = await _db!.query(
      offlineOrderStatusUpdateTrackTable,
      where: 'order_id = ? AND order_type = ?',
      whereArgs: [orderId, orderType],
    );
    return data.isNotEmpty;
  }

  Future<void> deleteOrderStatusUpdateTrack(
      String orderId, String orderType) async {
    await _db!.delete(
      offlineOrderStatusUpdateTrackTable,
      where: 'order_id = ? AND order_type = ?',
      whereArgs: [orderId, orderType],
    );
  }

  Future<void> clearOrderStatusUpdateTrack() async {
    await _db!.delete(offlineOrderStatusUpdateTrackTable);
  }

  Future<dynamic> saveInventoryOrder(
    String orderID,
    String orderNumber,
    Map<String, dynamic> data,
  ) async {
    await _db!.insert(offlineInventoryDispatchTable, {
      'order_id': orderID,
      'order_number': orderNumber,
      'data': jsonEncode(data),
    });
  }

  Future<List<Map<String, dynamic>>> offlineDispatchedOrders() async {
    return await _db!.query(offlineInventoryDispatchTable);
  }

  Future<void> deleteOfflineDispatchedOrder(orderData) async {
    await _db!.delete(
      offlineInventoryDispatchTable,
      where: 'order_id = ?',
      whereArgs: [orderData],
    );
  }
}
