import 'dart:typed_data';

class CategoryListDataModel {
  String? status;
  String? languageId;
  List<CategoryModel>? list;

  CategoryListDataModel({this.status, this.languageId, this.list});

  CategoryListDataModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    languageId = json['language_id'];
    if (json['list'] != null) {
      list = <CategoryModel>[];
      json['list'].forEach((v) {
        list!.add(CategoryModel.fromJson(v));
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

class CategoryModel {
  String? categoryId;
  String? categoryName;
  String? images;
  Uint8List? imageBlob;

  CategoryModel({this.categoryId, this.categoryName, this.images});

  CategoryModel.fromJson(Map<String, dynamic> json) {
    categoryId = json['category_id'];
    categoryName = json['category_name'];
    images = json['images'];
    if (json['imageBlob'] != null) {
      imageBlob = json['imageBlob'];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['category_id'] = categoryId;
    data['category_name'] = categoryName;
    data['images'] = images;
    return data;
  }

  // Future<void> save() async {
  //   Map<String, dynamic> map = toJson();
  //   FullVendorSQLDB.instance.insert('categories', map);
  // }
}
