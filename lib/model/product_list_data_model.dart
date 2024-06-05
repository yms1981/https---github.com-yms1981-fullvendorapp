import 'dart:convert';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../db/sql/cart_sql_helper.dart';

class ProductListDataModel {
  String? status;
  String? languageId;
  List<ProductDetailsDataModel>? list;

  ProductListDataModel({this.status, this.languageId, this.list});

  ProductListDataModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    languageId = json['language_id'];
    if (json['list'] != null) {
      list = <ProductDetailsDataModel>[];
      json['list'].forEach((v) {
        list!.add(ProductDetailsDataModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['language_id'] = languageId;
    if (list != null) {
      data['list'] = list!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ProductDetailsDataModel {
  String? catalogId;
  String? productId;
  String? name;
  String? sku;
  String? categoryId;
  String? salePrice;
  String? salePrice0;
  String? fobPrice;
  String? purchasePrice;
  String? barcode;
  String? tags;
  String? descriptions;
  String? unitType;
  String? stock;
  String? lblstock;
  String? totalOrder;
  double? availableStock;
  String? minimumStock;
  String? forceMoq;
  String? currencyType;
  List<Images>? images;
  int quantity = 0;
  bool isFav = false;
  List<dynamic>? requested;

  ProductDetailsDataModel({
    this.catalogId,
    this.productId,
    this.name,
    this.sku,
    this.categoryId,
    this.salePrice,
    this.salePrice0,
    this.fobPrice,
    this.purchasePrice,
    this.barcode,
    this.tags,
    this.descriptions,
    this.unitType,
    this.stock,
    this.totalOrder,
    this.availableStock,
    this.minimumStock,
    this.forceMoq,
    this.currencyType,
    this.images,
    this.quantity = 0,
    this.requested,
    this.lblstock,
  });

  int get moq {
    int value = (double.tryParse(minimumStock ?? '1') ?? 1).ceil();
    if (value == 0) {
      value = int.tryParse(minimumStock ?? '1') ?? 1;
    }
    return value < 1 ? 1 : value;
  }

  bool get isForceMoq => forceMoq == '1';

  ProductDetailsDataModel.fromJson(Map<String, dynamic> json) {
    catalogId = json['catalog_id'];
    productId = json['product_id'];
    name = json['name'];
    sku = json['sku'];
    categoryId = json['category_id'];
    salePrice = json['sale_price'];
    salePrice0 = json['sale_price0'];
    fobPrice = json['fob_price'];
    purchasePrice = json['purchase_price'];
    barcode = json['barcode'];
    tags = json['tags'];
    descriptions = json['descriptions'];
    unitType = json['unit_type'];
    stock = json['stock'];
    totalOrder = json['total_order'];
    if (json['available_stock'] is String) {
      availableStock = double.tryParse(json['available_stock'] ?? '0');
    } else if (json['available_stock'] is int) {
      availableStock = json["available_stock"].toDouble();
    } else if (json['available_stock'] is double) {
      availableStock = json['available_stock'];
    } else if (json['available_stock'] is num) {
      availableStock = json['available_stock'];
    }
    minimumStock = json['minimum_stock'];
    forceMoq = json['force_moq'] ?? json['notify_minimum_stock'];
    currencyType = json['currency_type'];

    if (json['images'] != null) {
      images = <Images>[];
      dynamic localImages = json['images'];
      if (localImages is String) {
        try {
          localImages = jsonDecode(localImages);
        } catch (_) {}
      }
      if (localImages is List) {
        for (var v in localImages) {
          images!.add(Images.fromJson(v));
        }
      } else {
        images!.add(Images.fromJson({"pic": localImages}));
      }
    }
    cartQuantityByProductId(productId ?? '').then((value) {
      quantity = value;
    });
    requested = json['requested'] ?? [];
    lblstock = json['lblstock'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['catalog_id'] = catalogId;
    data['product_id'] = productId;
    data['name'] = name;
    data['sku'] = sku;
    data['category_id'] = categoryId;
    data['sale_price'] = salePrice;
    data['sale_price0'] = salePrice0;
    data['fob_price'] = fobPrice;
    data['purchase_price'] = purchasePrice;
    data['barcode'] = barcode;
    data['tags'] = tags;
    data['descriptions'] = descriptions;
    data['unit_type'] = unitType;
    data['stock'] = stock;
    data['total_order'] = totalOrder;
    data['available_stock'] = availableStock;
    data['minimum_stock'] = minimumStock;
    data['force_moq'] = forceMoq;
    data['currency_type'] = currencyType;
    if (images != null) {
      data['images'] = images!.map((v) => v.toJson()).toList();
    }
    if (requested != null) {
      data['requested'] = requested!.map((v) => v.toJson()).toList();
    }
    data['quantity'] = quantity;
    return data;
  }

  Future<void> save({required Transaction txn, bool isUpdate = true}) async {
    Map<String, dynamic> productMap = toJson();
    // productMap['requested'] = jsonEncode(requested);
    productMap['images'] = jsonEncode(images);

    await txn.insert(
      'products',
      productMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

class Images {
  String? productId;
  String? companyId;
  String? imgId;
  String? pic;
  String? local;
  Uint8List? imageBlob;

  Images({this.productId, this.companyId, this.imgId, this.pic, this.local});

  Images.fromJson(Map<String, dynamic> json) {
    productId = json['product_id']?.toString();
    companyId = json['company_id']?.toString();
    imgId = json['img_id']?.toString() ?? json['image_id']?.toString();
    pic = json['pic']?.toString();
    local = json['local']?.toString();
    try {
      imageBlob = json['imageBlob'] != null
          ? Uint8List.fromList(json['imageBlob'].cast<int>())
          : null;
    } catch (e) {
      print(e);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product_id'] = productId;
    data['company_id'] = companyId;
    data['img_id'] = imgId;
    data['pic'] = pic;
    data['local'] = local;
    data['image_blob'] = imageBlob;
    return data;
  }
}
