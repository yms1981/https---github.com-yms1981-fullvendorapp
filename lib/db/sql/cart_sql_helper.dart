import 'dart:convert';

import 'package:FullVendor/db/sql/database.dart';
import 'package:FullVendor/model/product_list_data_model.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/cupertino.dart';

import '../../utils/extensions.dart';

ValueNotifier<int> cartQuantityNotifier = ValueNotifier<int>(0);

void updateCartQuantity() async {
  cartQuantityNotifier.value = await cartSumQuantity();
}

Future<int> cartQuantityByProductId(String productId) async {
  List<Map<String, dynamic>> results = await FullVendorSQLDB.instance.db
      .query('Cart', where: 'product_id = ?', whereArgs: [productId]);
  if (results.isEmpty) return 0;
  if (results.length > 1) print("More than one cart item found in db");
  return results.first['quantity'];
}

Future<String> notesByProductId(String productId) async {
  List<Map<String, dynamic>> results = await FullVendorSQLDB.instance.db
      .query('Cart', where: 'product_id = ?', whereArgs: [productId]);
  if (results.isEmpty) return '';
  if (results.length > 1) print("More than one cart item found in db");
  return results.first['notes'];
}

Future<int> cartSumQuantity() async {
  List<Map<String, dynamic>> results = await FullVendorSQLDB.instance.db
      .rawQuery('select sum(quantity) as quantity from Cart');

  if (results.isEmpty) return 0;
  return results.first['quantity'] ?? 0;
}

Future<int> cartItemQuantity() async {
  List<Map<String, dynamic>> results =
      await FullVendorSQLDB.instance.db.query('Cart');
  return results.length;
}

Future<List<Map<String, dynamic>>> loadCart() async {
  return await FullVendorSQLDB.instance.db.query('Cart');
}

Future<void> addToCart(
  ProductDetailsDataModel product,
  int quantity,
  String? notes,
) async {
  Decimal salePrice = Decimal.parse(product.salePrice ?? '0.0');
  // Decimal discount =
  //     Decimal.parse(defaultCustomerNotifier.value?.percentPriceAmount ?? '0.0');
  // bool increasePrice = defaultCustomerNotifier.value?.percentageOnPrice
  //         ?.toLowerCase()
  //         .contains("increase") ??
  //     true;
  // discount = discount * Decimal.parse("0.01");
  // int minimumStock = double.parse(product.minimumStock ?? '0').ceil();
  // if (minimumStock != 1) minimumStock = 1;
  // Decimal discountPrice = Decimal.parse("0.0");
  // if (increasePrice) {
  //   discountPrice = salePrice + (salePrice * discount);
  // } else {
  //   discountPrice = salePrice - (salePrice * discount);
  // }
  // Decimal finalSalePrice =
  //     discountPrice * Decimal.parse(minimumStock.toString());
  Map<String, dynamic> productMap = {};
  productMap['product_id'] = product.productId;
  productMap['quantity'] = quantity;
  productMap['notes'] = notes ?? '';
  productMap['sale_price'] = salePrice.toString();
  productMap['customer_id'] = defaultCustomerNotifier.value?.customerId ?? '';
  productMap['productData'] = jsonEncode(product.toJson());
  int updatesCount = await FullVendorSQLDB.instance.db.update(
    'Cart',
    {'quantity': quantity, 'notes': notes ?? ''},
    where: 'product_id = ?',
    whereArgs: [product.productId ?? '-1'],
  );
  if (updatesCount == 0) {
    await FullVendorSQLDB.instance.db.insert('Cart', productMap);
  }
  updateCartQuantity();
}

Future<void> removeFromCart(Map<String, dynamic> product) async {
  List<Map<String, dynamic>> results = await FullVendorSQLDB.instance.db.query(
      'Cart',
      where: 'product_id = ?',
      whereArgs: [product['product_id']]);
  if (results.isNotEmpty) {
    int quantityToSet = product['quantity'] ?? (results.first['quantity'] - 1);
    if (quantityToSet > 0) {
      await FullVendorSQLDB.instance.db.update(
          'Cart',
          {
            'quantity': (product['quantity'] ?? (results.first['quantity'] - 1))
          },
          where: 'product_id = ?',
          whereArgs: [product['product_id']]);
    } else {
      await FullVendorSQLDB.instance.db.delete('Cart',
          where: 'product_id = ?', whereArgs: [product['product_id']]);
    }
  }
  updateCartQuantity();
}

// check is in cart or not
Future<bool> isInCart(String productId) async {
  List<Map<String, dynamic>> results = await FullVendorSQLDB.instance.db
      .query('Cart', where: 'product_id = ?', whereArgs: [productId]);
  if (results.isEmpty) return false;
  return true;
}

Future<void> clearCart() async {
  await FullVendorSQLDB.instance.db.delete('Cart');
  updateCartQuantity();
}

Future<List<ProductDetailsDataModel>> getCart() async {
  List<Map<String, dynamic>> results =
      await FullVendorSQLDB.instance.db.query('Cart', where: 'quantity > 0');
  List<ProductDetailsDataModel> products = [];
  for (Map<String, dynamic> result in results) {
    Map<String, dynamic> productResults = jsonDecode(result['productData']);
    // productResults['sale_price'] = result['sale_price']?.toString();
    if (productResults.isEmpty) {
      print("Product not found in products table");
    } else {
      products.add(ProductDetailsDataModel.fromJson(productResults));
    }
  }
  return products;
}
