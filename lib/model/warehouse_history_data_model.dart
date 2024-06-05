import 'package:flutter/foundation.dart';

class WarehouseHistoryDataModel {
  String? businessName;
  String? name;
  String? discount;
  String? email;
  String? phone;
  String? tipoD;
  String? customerId;
  String? orderId;
  String? orderNumber;
  String? orderComments;
  String? created;
  String? discountType;
  String? updated;
  String? paymentMethod;
  String? paymentStatus;
  String? orderStatus;
  String? transactionId;
  String? nameStatusSpanish;
  String? nameStatusEnglish;
  List<ProductList>? productList;
  String? totalQuantity;
  String? adiscount;
  String? orderedTotal;
  String? totalamount;

  WarehouseHistoryDataModel(
      {this.businessName,
      this.name,
      this.discount,
      this.email,
      this.phone,
      this.tipoD,
      this.customerId,
      this.orderId,
      this.orderNumber,
      this.orderComments,
      this.created,
      this.discountType,
      this.updated,
      this.paymentMethod,
      this.paymentStatus,
      this.orderStatus,
      this.transactionId,
      this.nameStatusSpanish,
      this.nameStatusEnglish,
      this.productList,
      this.totalQuantity,
      this.adiscount,
      this.orderedTotal,
      this.totalamount});

  WarehouseHistoryDataModel.fromJson(Map<String, dynamic> json) {
    businessName = json['business_name'];
    name = json['name'];
    discount = json['discount'];
    email = json['email'];
    phone = json['phone'];
    tipoD = json['tipo_d'];
    customerId = json['customer_id'];
    orderId = json['order_id'];
    orderNumber = json['order_number'];
    orderComments = json['order_comments'];
    created = json['created'];
    discountType = json['discount_type'];
    updated = json['updated'];
    paymentMethod = json['payment_method'];
    paymentStatus = json['payment_status'];
    orderStatus = json['order_status'];
    transactionId = json['transaction_id'];
    nameStatusSpanish = json['name_status_spanish'];
    nameStatusEnglish = json['name_status_english'];
    if (json['product_list'] != null) {
      productList = <ProductList>[];
      json['product_list'].forEach((v) {
        productList!.add(ProductList.fromJson(v));
      });
    }
    totalQuantity = json['total_quantity'];
    adiscount = json['adiscount'];
    orderedTotal = json['ordered_total'];
    totalamount = json['totalamount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['business_name'] = this.businessName;
    data['name'] = this.name;
    data['discount'] = this.discount;
    data['email'] = this.email;
    data['phone'] = this.phone;
    data['tipo_d'] = this.tipoD;
    data['customer_id'] = this.customerId;
    data['order_id'] = this.orderId;
    data['order_number'] = this.orderNumber;
    data['order_comments'] = this.orderComments;
    data['created'] = this.created;
    data['discount_type'] = this.discountType;
    data['updated'] = this.updated;
    data['payment_method'] = this.paymentMethod;
    data['payment_status'] = this.paymentStatus;
    data['order_status'] = this.orderStatus;
    data['transaction_id'] = this.transactionId;
    data['name_status_spanish'] = this.nameStatusSpanish;
    data['name_status_english'] = this.nameStatusEnglish;
    if (this.productList != null) {
      data['product_list'] = this.productList!.map((v) => v.toJson()).toList();
    }
    data['total_quantity'] = this.totalQuantity;
    data['adiscount'] = this.adiscount;
    data['ordered_total'] = this.orderedTotal;
    data['totalamount'] = this.totalamount;
    return data;
  }
}

class ProductList {
  String? productId;
  String? detailId;
  String? barcode;
  String? sku;
  String? name;
  String? pack;
  String? deliveryPack;
  String? stock;
  int? totalOrder;
  int? availableStock;
  String? deliveredQuantity;
  int? availableDeliveredQuantity;
  String? salePrice;
  String? qty;
  String? deliveredQty;
  String? total;
  String? purchasePrice;
  String? discount;
  String? discountType;
  String? fobPrice;
  String? comment;
  String? currencyType;
  String? created;
  List<Images>? images;
  List<Requested>? requested;

  ProductList({
    this.currencyType,
    this.productId,
    this.name,
    this.sku,
    this.qty,
    this.pack,
    this.stock,
    this.totalOrder,
    this.availableStock,
    this.deliveredQuantity,
    this.availableDeliveredQuantity,
    this.salePrice,
    this.fobPrice,
    this.purchasePrice,
    this.barcode,
    this.discount,
    this.discountType,
    this.comment,
    this.created,
    this.images,
    this.requested,
    this.total,
    this.detailId,
    this.deliveredQty,
    this.deliveryPack,
  });

  ProductList.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'];
    detailId = json['detail_id'];
    barcode = json['barcode'];
    sku = json['sku'];
    name = json['name'];
    salePrice = json['sale_price'];
    qty = json['qty'];
    deliveredQty = json['delivered_qty'];
    total = json['total'];
    pack = json['pack'];
    deliveryPack = json['delivered_pack'];
    stock = json['stock'];
    totalOrder = json['total_order'];
    availableStock = json['available_stock'];
    deliveredQuantity = json['delivered_quantity'];
    availableDeliveredQuantity = json['available_delivered_quantity'];
    purchasePrice = json['purchase_price'];
    discount = json['discount'];
    discountType = json['discount_type'];
    fobPrice = json['fob_price'];
    comment = json['comment'];
    currencyType = json['currency_type'];
    created = json['created'];
    if (json['images'] != null) {
      images = <Images>[];
      json['images'].forEach((v) {
        images!.add(new Images.fromJson(v));
      });
    }
    if (json['requested'] != null) {
      requested = <Requested>[];
      json['requested'].forEach((v) {
        requested!.add(new Requested.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['currency_type'] = this.currencyType;
    data['product_id'] = this.productId;
    data['name'] = this.name;
    data['sku'] = this.sku;
    data['qty'] = this.qty;
    data['pack'] = this.pack;
    data['stock'] = this.stock;
    data['total_order'] = this.totalOrder;
    data['available_stock'] = this.availableStock;
    data['delivered_quantity'] = this.deliveredQuantity;
    data['available_delivered_quantity'] = this.availableDeliveredQuantity;
    data['sale_price'] = this.salePrice;
    data['fob_price'] = this.fobPrice;
    data['purchase_price'] = this.purchasePrice;
    data['barcode'] = this.barcode;
    data['discount'] = this.discount;
    data['discount_type'] = this.discountType;
    data['comment'] = this.comment;
    data['created'] = this.created;
    if (this.images != null) {
      data['images'] = this.images!.map((v) => v.toJson()).toList();
    }
    if (this.requested != null) {
      data['requested'] = this.requested!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Images {
  int? productId;
  int? companyId;
  int? imgId;
  String? pic;
  String? local;
  Uint8List? imageBlob;

  Images({this.productId, this.companyId, this.imgId, this.pic, this.local});

  Images.fromJson(Map<String, dynamic> json) {
    productId = int.tryParse(json['product_id']?.toString() ?? '-1') ?? -1;
    companyId = int.tryParse(json['company_id']?.toString() ?? '-1') ?? -1;
    imgId =
        int.tryParse((json['image_id'] ?? json['img_id'] ?? 0).toString()) ??
            -1;
    pic = json['pic'];
    local = json['local'];
    if (json['imageBlob'] != null) {
      imageBlob = json['imageBlob'];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['product_id'] = this.productId;
    data['company_id'] = this.companyId;
    data['img_id'] = this.imgId;
    data['pic'] = this.pic;
    data['local'] = this.local;
    return data;
  }
}

class Requested {
  String? customerId;
  String? qty;
  String? requested;

  Requested({this.customerId, this.qty, this.requested});

  Requested.fromJson(Map<String, dynamic> json) {
    customerId = json['customer_id'];
    qty = json['qty'];
    requested = json['requested'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['customer_id'] = this.customerId;
    data['qty'] = this.qty;
    data['requested'] = this.requested;
    return data;
  }
}
