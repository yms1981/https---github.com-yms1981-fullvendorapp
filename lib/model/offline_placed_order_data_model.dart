import 'dart:convert';

import 'package:FullVendor/model/place_order_model.dart';

class OfflineOrderDataModel {
  OrderPlaceRequestBody? orderData;
  String? orderMode;
  int? orderCreateTime;
  int? orderID;

  OfflineOrderDataModel({
    this.orderID,
    this.orderData,
    this.orderMode,
    this.orderCreateTime,
  });

  factory OfflineOrderDataModel.fromJson(Map<String, dynamic> json) =>
      OfflineOrderDataModel(
        orderData: json["orderData"] == null
            ? null
            : OrderPlaceRequestBody.fromJson(jsonDecode(json["orderData"])),
        orderMode: json["orderMode"],
        orderCreateTime: json["orderCreateTime"],
        orderID: json["order_id"],
      );
}
