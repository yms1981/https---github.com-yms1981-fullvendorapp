class OrderPlaceRequestBody {
  String id = "";
  String created = "";
  String contactName = "";
  String bussName = "";
  String tipod = "";
  String orderstatus = "";
  String userId = "";
  String languageId = "";
  String customerId = "";
  String orderComment = "";
  String discount = "";
  String discountType = "";
  String amount = "";
  List<OrderPlaceList>? itemList;
  String companyId = "";

  OrderPlaceRequestBody({
    this.id = "",
    this.created = "",
    this.contactName = "",
    this.bussName = "",
    this.tipod = "",
    this.orderstatus = "",
    this.userId = "",
    this.languageId = "",
    this.customerId = "",
    this.orderComment = "",
    this.discount = "",
    this.discountType = "",
    this.amount = "",
    this.itemList,
  });

  OrderPlaceRequestBody.fromJson(Map<String, dynamic> json) {
    // OrderPlaceRequestBody orderPlaceRequestBody = OrderPlaceRequestBody();
    id = json['Id'] ?? "";
    created = json['created'] ?? "";
    contactName = json['contactName'] ?? "";
    bussName = json['bussName'] ?? "";
    tipod = json['tipo_d'] ?? "";
    orderstatus = json['order_status'] ?? "";
    userId = json['user_id'] ?? "";
    languageId = json['language_id'] ?? "";
    customerId = json['customer_id'] ?? "";
    orderComment = json['order_comment'] ?? "";
    discount = json['discount'] ?? "";
    discountType = json['discount_type'] ?? "";
    amount = json['amount'] ?? "";
    itemList = (json['itemList'] as List<dynamic>?)
            ?.map((e) => OrderPlaceList.fromJson(e))
            .toList() ??
        <OrderPlaceList>[];
    companyId = json['company_id'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['Id'] = id;
    data['created'] = created;
    data['contactName'] = contactName;
    data['bussName'] = bussName;
    data['tipo_d'] = tipod;
    data['order_status'] = orderstatus;
    data['user_id'] = userId;
    data['language_id'] = languageId;
    data['customer_id'] = customerId;
    data['order_comment'] = orderComment;
    data['discount'] = discount;
    data['discount_type'] = discountType;
    data['amount'] = amount;
    data['itemList'] =
        itemList?.map((e) => e.toJson()).toList() ?? <OrderPlaceList>[];
    data['company_id'] = companyId;
    return data;
  }
}

class OrderPlaceList {
  String? productId;
  String? qty;
  String? discount;
  String? discountType;
  String? comment;
  String? groupcustomer;
  String? tipolista;
  double percprice = 0.0;
  double salesp = 0.0;
  double impprice = 0.0;
  double totalprice = 0.0;

  OrderPlaceList();

  OrderPlaceList.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'];
    qty = json['qty'];
    discount = json['discount'];
    discountType = json['discount_type'];
    comment = json['comment'];
    groupcustomer = json['groupcustomer'];
    tipolista = json['tipolista'];
    percprice = (json['perc_price'] ?? 0.0).toDouble();
    salesp = (json['salesp'] ?? 0.0).toDouble();
    impprice = (json['impprice'] ?? 0.0).toDouble();
    totalprice = (json['totalprice'] ?? 0.0).toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['product_id'] = productId;
    data['qty'] = qty;
    data['discount'] = discount;
    data['discount_type'] = discountType;
    data['comment'] = comment;
    data['groupcustomer'] = groupcustomer;
    data['tipolista'] = tipolista;
    data['perc_price'] = percprice;
    data['salesp'] = salesp;
    data['impprice'] = impprice;
    data['totalprice'] = totalprice;
    return data;
  }
}
