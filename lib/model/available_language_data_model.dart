class LanguageDataModel {
  String? status;
  List<Languages>? languages;

  LanguageDataModel({this.status, this.languages});

  LanguageDataModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['languages'] != null) {
      languages = <Languages>[];
      json['languages'].forEach((v) {
        languages!.add(new Languages.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    if (this.languages != null) {
      data['languages'] = this.languages!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Languages {
  String? languageId;
  String? name;
  String? iso6391;
  String? status;

  Languages({this.languageId, this.name, this.iso6391, this.status});

  Languages.fromJson(Map<String, dynamic> json) {
    languageId = json['language_id'];
    name = json['name'];
    iso6391 = json['iso_639_1'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['language_id'] = this.languageId;
    data['name'] = this.name;
    data['iso_639_1'] = this.iso6391;
    data['status'] = this.status;
    return data;
  }
}
