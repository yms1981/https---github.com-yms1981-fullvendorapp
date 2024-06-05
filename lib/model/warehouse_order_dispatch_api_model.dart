class OrderDispatchAPIRequestModel {
  String? deliveryStatus;
  String? orderId;
  String? orderStatus;
  List<OrderReceivedProductList>? productlist;

  OrderDispatchAPIRequestModel({
    this.deliveryStatus,
    this.orderId,
    this.orderStatus,
    this.productlist,
  });

  OrderDispatchAPIRequestModel.fromJson(Map<String, dynamic> json) {
    deliveryStatus = json['delivery_status'];
    orderId = json['order_id'];
    orderStatus = json['order_status'];
    if (json['productlist'] != null) {
      productlist = List<OrderReceivedProductList>.from(json['productlist'].map(
        (product) => OrderReceivedProductList.fromJson(product),
      ));
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['delivery_status'] = deliveryStatus;
    data['order_id'] = orderId;
    data['order_status'] = orderStatus;
    if (productlist != null) {
      data['productlist'] =
          productlist!.map((product) => product.toJson()).toList();
    }
    return data;
  }
}

class OrderReceivedProductList {
  String? productId;
  String? deliveredQuantity;
  String? deliveredPack;

  OrderReceivedProductList({
    this.productId,
    this.deliveredQuantity,
    this.deliveredPack,
  });

  OrderReceivedProductList.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'];
    deliveredQuantity = json['delivered_quantity'];
    deliveredPack = json['delivered_pack'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['product_id'] = productId;
    data['delivered_quantity'] = deliveredQuantity;
    data['delivered_pack'] =
        (int.tryParse(deliveredPack ?? '0') ?? 0).toString();
    return data;
  }
}
