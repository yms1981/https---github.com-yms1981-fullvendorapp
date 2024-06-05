class DatabaseVersionCheckModel {
  String? status;
  List<VersionCheckModel>? list;

  DatabaseVersionCheckModel({this.status, this.list});

  DatabaseVersionCheckModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['list'] != null) {
      list = <VersionCheckModel>[];
      json['list'].forEach((v) {
        list!.add(VersionCheckModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    if (list != null) {
      data['list'] = list!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class VersionCheckModel {
  String? update;
  String? companyId;
  String? version;
  bool isUpdateAvailable = false;
  bool isMicroUpdateAvailable = false;

  VersionCheckModel({
    this.update,
    this.companyId,
    this.version,
    this.isMicroUpdateAvailable = false,
  });

  VersionCheckModel.fromJson(Map<String, dynamic> json) {
    update = json['update'];
    companyId = json['company_id'];
    version = json['version'];
    isMicroUpdateAvailable = json['isMicroUpdateAvailable'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['update'] = update;
    data['company_id'] = companyId;
    data['version'] = version;
    data['isMicroUpdateAvailable'] = isMicroUpdateAvailable;
    return data;
  }
}
