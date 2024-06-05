// Future<List<Map<String, dynamic>>> loadSavedCustomers(
//     {bool sortAscending = true}) async {
//   print("loadSavedCustomers");
//   dynamic response = await FullVendorSQLDB.instance.db
//       .query('customers', orderBy: 'name ${sortAscending ? 'ASC' : 'DESC'}');
//   print("loadSavedCustomers response");
//   return response;
// }

// Future<List<Map<String, dynamic>>> loadDefaultCustomers() async {
//   return await FullVendorSQLDB.instance.db
//       .query("customers", where: "isDefault = ?", whereArgs: ["1"]);
// }

// // set default customer by id
// Future<void> setDefaultCustomerId(String id) async {
//   await FullVendorSQLDB.instance.db.update('customers', {'isDefault': '0'},
//       where: 'isDefault = ?', whereArgs: ['1']);
//   await FullVendorSQLDB.instance.db.update('customers', {'isDefault': '1'},
//       where: 'id = ?', whereArgs: [id]);
// }
//
// Future<List<Map<String, dynamic>>> loadCategoryFromDB(
//     {required bool sortAscending}) async {
//   return await FullVendorSQLDB.instance.db.query('categories',
//       orderBy: 'category_name ${sortAscending ? 'ASC' : 'DESC'}');
// }
//
// Future<CategoryListDataModel> loadLocalCategory(
//     {required bool sortAscending}) async {
//   List<Map<String, dynamic>> categories =
//       await loadCategoryFromDB(sortAscending: sortAscending);
//   Map<String, dynamic> categoryMap = {};
//   categoryMap['list'] = categories;
//   return CategoryListDataModel.fromJson(categoryMap);
// }
//
// Future<ProductListDataModel> loadLocalProducts({
//   String? categoryId,
//   String? customerID,
// }) async {
//   List<Map<String, dynamic>> products = await FullVendorSQLDB.instance.db
//       .rawQuery('SELECT * FROM products WHERE category_id = $categoryId');
//   Map<String, dynamic> productMap = {};
//   productMap['list'] = products;
//   return ProductListDataModel.fromJson(productMap);
// }
//
// Future<Map<String, dynamic>> loggedInUserProfile() async {
//   List<Map<String, dynamic>> users =
//       await FullVendorSQLDB.instance.db.query('users');
//   if (users.isEmpty) return {};
//   if (users.length > 1) print("More than one user found in db");
//   return users.first;
// }
//
// Future<int> productCounts() async {
//   List<Map<String, dynamic>> products =
//       await FullVendorSQLDB.instance.db.query('products');
//   return products.length;
// }
//
// Future<List<Map<String, dynamic>>> searchProductsLocally(String query) async {
//   List<Map<String, dynamic>> products = await FullVendorSQLDB.instance.db
//       .query('products', where: 'name LIKE ?', whereArgs: ['%$query%']);
//   return products;
// }
//
// Future<int> insertOrderHistory(OrderList order) async {
//   Map<String, dynamic> orderMap = order.toJson();
//   String orderJson = json.encode(orderMap);
//
//   return await FullVendorSQLDB.instance.db.insert('OrderHistory', {
//     'order_id': order.orderId,
//     'order_details': orderJson,
//   });
// }
//
// Future<List<OrderList>> getOrderHistory() async {
//   List<Map<String, dynamic>> results =
//       await FullVendorSQLDB.instance.db.query('OrderHistory');
//   List<OrderList> orderHistory = [];
//
//   for (var result in results) {
//     String orderJson = result['order_details'];
//     Map<String, dynamic> orderMap = json.decode(orderJson);
//     OrderList order = OrderList.fromJson(orderMap);
//     orderHistory.add(order);
//   }
//
//   return orderHistory;
// }
