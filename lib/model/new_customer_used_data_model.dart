class PaymentTypeOptionsDataModel {
  String? status;
  String? languageId;
  List<TermsOfSalesOptionsDataModel>? list;

  PaymentTypeOptionsDataModel({this.status, this.languageId, this.list});

  PaymentTypeOptionsDataModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    languageId = json['language_id'];
    if (json['list'] != null) {
      list = <TermsOfSalesOptionsDataModel>[];
      json['list'].forEach((v) {
        list!.add(new TermsOfSalesOptionsDataModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['language_id'] = this.languageId;
    if (this.list != null) {
      data['list'] = this.list!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class TermsOfSalesOptionsDataModel {
  String? termId;
  String? languageId;
  String? companyId;
  String? userId;
  String? name;
  String? createdAt;
  String? termStatus;
  String? isDefault;

  TermsOfSalesOptionsDataModel({
    this.termId,
    this.languageId,
    this.companyId,
    this.userId,
    this.name,
    this.createdAt,
    this.termStatus,
    this.isDefault,
  });

  TermsOfSalesOptionsDataModel.fromJson(Map<String, dynamic> json) {
    termId = json['term_id'];
    languageId = json['language_id'];
    companyId = json['company_id'];
    userId = json['user_id'];
    name = json['name'];
    createdAt = json['created_at'];
    termStatus = json['term_status'];
    isDefault = json['default'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['term_id'] = this.termId;
    data['language_id'] = this.languageId;
    data['company_id'] = this.companyId;
    data['user_id'] = this.userId;
    data['name'] = this.name;
    data['created_at'] = this.createdAt;
    data['term_status'] = this.termStatus;
    data['default'] = this.isDefault;
    return data;
  }
}

class GroupTypeOptionsDataModel {
  String? status;
  String? languageId;
  List<GroupTypeDetails>? list;

  GroupTypeOptionsDataModel({this.status, this.languageId, this.list});

  GroupTypeOptionsDataModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    languageId = json['language_id'];
    if (json['list'] != null) {
      list = <GroupTypeDetails>[];
      json['list'].forEach((v) {
        list!.add(new GroupTypeDetails.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['language_id'] = this.languageId;
    if (this.list != null) {
      data['list'] = this.list!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class GroupTypeDetails {
  String? groupId;
  String? languageId;
  String? companyId;
  String? userId;
  String? name;
  String? percentageOnPrice;
  String? createdAt;
  String? groupStatus;

  GroupTypeDetails(
      {this.groupId,
      this.languageId,
      this.companyId,
      this.userId,
      this.name,
      this.percentageOnPrice,
      this.createdAt,
      this.groupStatus});

  GroupTypeDetails.fromJson(Map<String, dynamic> json) {
    groupId = json['group_id'];
    languageId = json['language_id'];
    companyId = json['company_id'];
    userId = json['user_id'];
    name = json['name'];
    percentageOnPrice = json['percentage_on_price'];
    createdAt = json['created_at'];
    groupStatus = json['group_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['group_id'] = this.groupId;
    data['language_id'] = this.languageId;
    data['company_id'] = this.companyId;
    data['user_id'] = this.userId;
    data['name'] = this.name;
    data['percentage_on_price'] = this.percentageOnPrice;
    data['created_at'] = this.createdAt;
    data['group_status'] = this.groupStatus;
    return data;
  }
}
