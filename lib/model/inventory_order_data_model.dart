import 'package:FullVendor/model/product_list_data_model.dart';

class WarehouseInventoryOrderDataModel {
  String? status;
  String? languageId;
  String? companyId;
  List<OrderList>? orderList;

  WarehouseInventoryOrderDataModel(
      {this.status, this.languageId, this.companyId, this.orderList});

  WarehouseInventoryOrderDataModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    languageId = json['language_id'];
    companyId = json['company_id'];
    if (json['order_list'] != null) {
      orderList = <OrderList>[];
      json['order_list'].forEach((v) {
        orderList!.add(OrderList.fromJson(v));
      });
    } else {
      orderList = <OrderList>[];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['status'] = status;
    data['language_id'] = languageId;
    data['company_id'] = companyId;
    if (orderList != null) {
      data['order_list'] = orderList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class OrderList {
  String? orderId;
  String? orderNumber;
  String? orderComments;
  String? orderedTotal;
  String? adiscount;
  String? totalamount;
  String? totalQuantity;
  String? totalAvailableDeliveredQuantity;
  String? discount;
  String? seller;
  String? paymentMethod;
  String? paymentStatus;
  String? transactionId;
  String? orderStatus;
  String? discountType;
  String? businessName;
  String? customerId;
  String? name;
  String? email;
  String? phone;
  String? created;
  String? updated;
  String? nameStatusSpanish;
  String? nameStatusEnglish;
  String? scolor;
  List<ProductList>? productList;

  OrderList({
    this.orderId,
    this.orderNumber,
    this.orderComments,
    this.orderedTotal,
    this.adiscount,
    this.totalamount,
    this.totalQuantity,
    this.totalAvailableDeliveredQuantity,
    this.discount,
    this.seller,
    this.paymentMethod,
    this.paymentStatus,
    this.transactionId,
    this.orderStatus,
    this.discountType,
    this.businessName,
    this.customerId,
    this.name,
    this.email,
    this.phone,
    this.created,
    this.updated,
    this.nameStatusSpanish,
    this.nameStatusEnglish,
    this.scolor,
    this.productList,
  });

  OrderList.fromJson(Map<String, dynamic> json) {
    orderId = json['order_id'];
    orderNumber = json['order_number'];
    orderComments = json['order_comments'];
    orderedTotal = json['ordered_total'];
    adiscount = json['adiscount'];
    totalamount = json['totalamount'];
    totalQuantity = json['total_quantity'];
    totalAvailableDeliveredQuantity =
        json['total_available_delivered_quantity'];
    discount = json['discount'];
    seller = json['seller'];
    paymentMethod = json['payment_method'];
    paymentStatus = json['payment_status'];
    transactionId = json['transaction_id'];
    orderStatus = json['order_status'];
    discountType = json['discount_type'];
    businessName = json['business_name'];
    customerId = json['customer_id'];
    name = json['name'];
    email = json['email'];
    phone = json['phone'];
    created = json['created'];
    updated = json['updated'];
    nameStatusSpanish = json['name_status_spanish'];
    nameStatusEnglish = json['name_status_english'];
    scolor = json['scolor'];
    if (json['product_list'] != null) {
      productList = <ProductList>[];
      json['product_list'].forEach((v) {
        productList!.add(ProductList.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['order_id'] = orderId;
    data['order_number'] = orderNumber;
    data['order_comments'] = orderComments;
    data['ordered_total'] = orderedTotal;
    data['adiscount'] = adiscount;
    data['totalamount'] = totalamount;
    data['total_quantity'] = totalQuantity;
    data['total_available_delivered_quantity'] =
        totalAvailableDeliveredQuantity;
    data['discount'] = discount;
    data['seller'] = seller;
    data['payment_method'] = paymentMethod;
    data['payment_status'] = paymentStatus;
    data['transaction_id'] = transactionId;
    data['order_status'] = orderStatus;
    data['discount_type'] = discountType;
    data['business_name'] = businessName;
    data['customer_id'] = customerId;
    data['name'] = name;
    data['email'] = email;
    data['phone'] = phone;
    data['created'] = created;
    data['updated'] = updated;
    data['name_status_spanish'] = nameStatusSpanish;
    data['name_status_english'] = nameStatusEnglish;
    data['scolor'] = scolor;
    if (productList != null) {
      data['product_list'] = productList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ProductList {
  String? currencyType;
  String? productId;
  String? name;
  String? sku;
  String? qty;
  String? pack;
  String? stock;
  int? totalOrder;
  int? availableStock;
  String? deliveredQuantity;
  int? availableDeliveredQuantity;
  String? salePrice;
  String? fobPrice;
  String? purchasePrice;
  String? barcode;
  String? discount;
  String? discountType;
  String? comment;
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
  });

  ProductList.fromJson(Map<String, dynamic> json) {
    currencyType = json['currency_type'];
    productId = json['product_id'];
    name = json['name'];
    sku = json['sku'];
    qty = json['qty'];
    pack = json['pack'];
    stock = json['stock'];
    totalOrder = json['total_order'];
    availableStock = json['available_stock'];
    deliveredQuantity = json['delivered_quantity'];
    availableDeliveredQuantity = json['available_delivered_quantity'];
    salePrice = json['sale_price'];
    fobPrice = json['fob_price'];
    purchasePrice = json['purchase_price'];
    barcode = json['barcode'];
    discount = json['discount'];
    discountType = json['discount_type'];
    comment = json['comment'];
    created = json['created'];
    if (json['images'] != null) {
      images = <Images>[];
      json['images'].forEach((v) {
        images!.add(Images.fromJson(v));
      });
    }
    if (json['requested'] != null) {
      requested = <Requested>[];
      json['requested'].forEach((v) {
        requested!.add(Requested.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['currency_type'] = currencyType;
    data['product_id'] = productId;
    data['name'] = name;
    data['sku'] = sku;
    data['qty'] = qty;
    data['pack'] = pack;
    data['stock'] = stock;
    data['total_order'] = totalOrder;
    data['available_stock'] = availableStock;
    data['delivered_quantity'] = deliveredQuantity;
    data['available_delivered_quantity'] = availableDeliveredQuantity;
    data['sale_price'] = salePrice;
    data['fob_price'] = fobPrice;
    data['purchase_price'] = purchasePrice;
    data['barcode'] = barcode;
    data['discount'] = discount;
    data['discount_type'] = discountType;
    data['comment'] = comment;
    data['created'] = created;
    if (images != null) {
      data['images'] = images!.map((v) => v.toJson()).toList();
    }
    if (requested != null) {
      data['requested'] = requested!.map((v) => v.toJson()).toList();
    }
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
    final Map<String, dynamic> data = {};
    data['customer_id'] = customerId;
    data['qty'] = qty;
    data['requested'] = requested;
    return data;
  }
}
