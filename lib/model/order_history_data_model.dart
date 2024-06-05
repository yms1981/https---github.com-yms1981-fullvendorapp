class OrdersHistoryDataModel {
  String? status;
  String? languageId;
  String? userId;
  List<OrderList>? orderList;

  OrdersHistoryDataModel({
    this.status,
    this.languageId,
    this.userId,
    this.orderList,
  });

  OrdersHistoryDataModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    languageId = json['language_id'];
    userId = json['user_id'];
    if (json['order_list'] != null) {
      orderList = <OrderList>[];
      json['order_list'].forEach((v) {
        orderList!.add(OrderList.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['language_id'] = languageId;
    data['user_id'] = userId;
    if (orderList != null) {
      data['order_list'] = orderList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class OrderList {
  String? tipoD;
  String? orderId;
  String? orderNumber;
  String? orderComments;
  String? orderedTotal;
  String? discount;
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
  String? totalamount;
  String? adiscount;
  String? discounta;
  String? amount;
  // String? warehouseUserId;
  // String? warehouseAssignDate;
  // String? warehouseName;
  List<ProductList>? productList;

  OrderList(
      {this.tipoD,
      this.orderId,
      this.orderNumber,
      this.orderComments,
      this.orderedTotal,
      this.discount,
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
      this.totalamount,
      this.adiscount,
      this.discounta,
      this.amount,
      // this.warehouseUserId,
      // this.warehouseAssignDate,
      // this.warehouseName,
      this.productList});

  OrderList.fromJson(Map<String, dynamic> json) {
    tipoD = json['tipo_d'];
    orderId = json['order_id'];
    orderNumber = json['order_number'];
    orderComments = json['order_comments'];
    orderedTotal = json['ordered_total'];
    discount = json['discount'];
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
    totalamount = json['totalamount'];
    adiscount = json['adiscount'];
    discounta = json['adiscount'] ?? json['discount_a'];
    amount = json['amount'] ?? '0.00';
    // warehouseUserId = json['warehouse_user_id'];
    // warehouseAssignDate = json['warehouse_assign_date'];
    // warehouseName = json['warehouse_name'];
    if (json['product_list'] != null) {
      productList = <ProductList>[];
      json['product_list'].forEach((v) {
        productList!.add(ProductList.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tipo_d'] = tipoD;
    data['order_id'] = orderId;
    data['order_number'] = orderNumber;
    data['order_comments'] = orderComments;
    data['ordered_total'] = orderedTotal;
    data['discount'] = discount;
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
    // data['warehouse_user_id'] = warehouseUserId;
    // data['warehouse_assign_date'] = warehouseAssignDate;
    // data['warehouse_name'] = warehouseName;
    if (productList != null) {
      data['product_list'] = productList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ProductList {
  String? orderId;
  String? currencyType;
  String? productId;
  String? name;
  String? sku;
  String? qty;
  String? salePrice;
  String? fobPrice;
  String? purchasePrice;
  String? barcode;
  String? discount;
  String? discountType;
  String? comment;
  String? created;
  List<Images>? images;

  ProductList({
    this.orderId,
    this.currencyType,
    this.productId,
    this.name,
    this.sku,
    this.qty,
    this.salePrice,
    this.fobPrice,
    this.purchasePrice,
    this.barcode,
    this.discount,
    this.discountType,
    this.comment,
    this.created,
    this.images,
  });

  ProductList.fromJson(Map<String, dynamic> json) {
    orderId = json['order_id'];
    currencyType = json['currency_type'];
    productId = json['product_id'];
    name = json['name'];
    sku = json['sku'];
    qty = json['qty'];
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
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['order_id'] = orderId;
    data['currency_type'] = currencyType;
    data['product_id'] = productId;
    data['name'] = name;
    data['sku'] = sku;
    data['qty'] = qty;
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
    return data;
  }
}

class Images {
  int? id;
  int? productId;
  int? imageId;
  int? companyId;
  String? pic;
  String? local;
  List<int>? imageBlob;

  Images({
    this.id,
    this.productId,
    this.imageId,
    this.companyId,
    this.pic,
    this.local,
    this.imageBlob,
  });

  Images.fromJson(Map<String, dynamic> json) {
    id = json['Id'];
    productId = int.tryParse(json['product_id']?.toString() ?? '-1') ?? -1;
    imageId = json['image_id'];
    companyId = int.tryParse(json['company_id']?.toString() ?? '-1') ?? -1;
    pic = json['pic'];
    local = json['local'];
    try {
      imageBlob = json['imageBlob'].cast<int>();
    } catch (e) {
      imageBlob = [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Id'] = this.id;
    data['product_id'] = this.productId;
    data['image_id'] = this.imageId;
    data['company_id'] = this.companyId;
    data['pic'] = this.pic;
    data['local'] = this.local;
    data['imageBlob'] = this.imageBlob;
    return data;
  }
}
