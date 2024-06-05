class CustomerListDataModel {
  String? status;
  String? languageId;
  List<Customer>? list;

  CustomerListDataModel({this.status, this.languageId, this.list});

  CustomerListDataModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    languageId = json['language_id'];
    if (json['list'] != null) {
      list = <Customer>[];
      json['list'].forEach((v) {
        list!.add(Customer.fromJson(v));
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

class Customer {
  int? id;
  String? selection;
  String? customerId;
  String? languageId;
  String? companyId;
  String? userId;
  String? name;
  String? businessName;
  String? taxId;
  String? discount;
  String? termId;
  String? termName;
  String? groupId;
  String? groupName;
  String? percentageOnPrice;
  String? percentPriceAmount;
  String? email;
  String? phone;
  String? cellPhone;
  String? notes;
  String? commercialAddress;
  String? commercialDeliveryAddress;
  String? commercialCountry;
  String? commercialState;
  String? commercialCity;
  String? commercialZone;
  String? commercialZipCode;
  String? dispatchAddress;
  String? dispatchDeliveryAddress;
  String? dispatchCountry;
  String? dispatchState;
  String? dispatchCity;
  String? dispatchZone;
  String? dispatchZipCode;
  String? dispatchShippingNotes;
  String? catalogEmails;
  String? customerCreatedAt;
  String? customerStatus;

  Customer({
    this.id,
    this.selection,
    this.customerId,
    this.languageId,
    this.companyId,
    this.userId,
    this.name,
    this.businessName,
    this.taxId,
    this.discount,
    this.termId,
    this.termName,
    this.groupId,
    this.groupName,
    this.percentageOnPrice,
    this.percentPriceAmount,
    this.email,
    this.phone,
    this.cellPhone,
    this.notes,
    this.commercialAddress,
    this.commercialDeliveryAddress,
    this.commercialCountry,
    this.commercialState,
    this.commercialCity,
    this.commercialZone,
    this.commercialZipCode,
    this.dispatchAddress,
    this.dispatchDeliveryAddress,
    this.dispatchCountry,
    this.dispatchState,
    this.dispatchCity,
    this.dispatchZone,
    this.dispatchZipCode,
    this.dispatchShippingNotes,
    this.catalogEmails,
    this.customerCreatedAt,
    this.customerStatus,
  });

  Customer.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    selection = json['selection'];
    customerId = json['customer_id'];
    languageId = json['language_id'];
    companyId = json['company_id'];
    userId = json['user_id'];
    name = json['name'];
    businessName = json['business_name'];
    taxId = json['tax_id'];
    discount = json['discount'];
    termId = json['term_id'];
    termName = json['term_name'];
    groupId = json['group_id'];
    groupName = json['group_name'];
    percentageOnPrice = json['percentage_on_price'];
    percentPriceAmount = json['percent_price_amount'];
    email = json['email'];
    phone = json['phone'];
    cellPhone = json['cell_phone'];
    notes = json['notes'];
    commercialAddress = json['commercial_address'];
    commercialDeliveryAddress = json['commercial_delivery_address'];
    commercialCountry = json['commercial_country'];
    commercialState = json['commercial_state'];
    commercialCity = json['commercial_city'];
    commercialZone = json['commercial_zone'];
    commercialZipCode = json['commercial_zip_code'];
    dispatchAddress = json['dispatch_address'];
    dispatchDeliveryAddress = json['dispatch_delivery_address'];
    dispatchCountry = json['dispatch_country'];
    dispatchState = json['dispatch_state'];
    dispatchCity = json['dispatch_city'];
    dispatchZone = json['dispatch_zone'];
    dispatchZipCode = json['dispatch_zip_code'];
    dispatchShippingNotes = json['dispatch_shipping_notes'];
    catalogEmails = json['catalog_emails'];
    customerCreatedAt = json['customer_created_at'];
    customerStatus = json['customer_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['selection'] = selection;
    data['customer_id'] = customerId;
    data['language_id'] = languageId;
    data['company_id'] = companyId;
    data['user_id'] = userId;
    data['name'] = name;
    data['business_name'] = businessName;
    data['tax_id'] = taxId;
    data['discount'] = discount;
    data['term_id'] = termId;
    data['term_name'] = termName;
    data['group_id'] = groupId;
    data['group_name'] = groupName;
    data['percentage_on_price'] = percentageOnPrice;
    data['percent_price_amount'] = percentPriceAmount;
    data['email'] = email;
    data['phone'] = phone;
    data['cell_phone'] = cellPhone;
    data['notes'] = notes;
    data['commercial_address'] = commercialAddress;
    data['commercial_delivery_address'] = commercialDeliveryAddress;
    data['commercial_country'] = commercialCountry;
    data['commercial_state'] = commercialState;
    data['commercial_city'] = commercialCity;
    data['commercial_zone'] = commercialZone;
    data['commercial_zip_code'] = commercialZipCode;
    data['dispatch_address'] = dispatchAddress;
    data['dispatch_delivery_address'] = dispatchDeliveryAddress;
    data['dispatch_country'] = dispatchCountry;
    data['dispatch_state'] = dispatchState;
    data['dispatch_city'] = dispatchCity;
    data['dispatch_zone'] = dispatchZone;
    data['dispatch_zip_code'] = dispatchZipCode;
    data['dispatch_shipping_notes'] = dispatchShippingNotes;
    data['catalog_emails'] = catalogEmails;
    data['customer_created_at'] = customerCreatedAt;
    data['customer_status'] = customerStatus;
    return data;
  }

  // Future<void> saveList({Transaction? db}) async {
  //   if (db != null) {
  //     await db.insert('customers', toJson());
  //   } else {
  //     await FullVendorSQLDB.instance.insert('customers', toJson());
  //   }
  // }
}
