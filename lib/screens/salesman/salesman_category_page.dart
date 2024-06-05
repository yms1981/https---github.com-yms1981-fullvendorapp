import 'dart:typed_data';

import 'package:FullVendor/db/synced_db.dart';
import 'package:FullVendor/network/apis.dart';
import 'package:FullVendor/screens/salesman/salesman_product_page.dart';
import 'package:FullVendor/widgets/app_theme_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../application/application_global_keys.dart';
import '../../application/theme.dart';
import '../../model/category_data_model.dart';
import '../../widgets/full_vendor_cache_image_loader.dart';
import '../../widgets/refresh_indicator.dart';
import '../../widgets/salesman/salesman_fragment_header_widget.dart';
import '../../widgets/selected_customer_widget.dart';

class SalesmanCategorySelectionPage extends StatefulWidget {
  const SalesmanCategorySelectionPage({super.key});
  static const String routeName = '/salesman/category';

  @override
  State<SalesmanCategorySelectionPage> createState() => _SalesmanCategorySelectionPageState();
}

class _SalesmanCategorySelectionPageState extends State<SalesmanCategorySelectionPage> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  CategoryListDataModel? _categoryListDataModel;
  String? _searchText;
  bool sortAscending = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      var text = _searchController.text.trim();
      if (text.isEmpty) {
        _searchText = null;
      } else {
        _searchText = text;
      }
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      appBar: Column(
        children: [
          Column(
            children: [
              SalesmanTopBar(
                title: tr('categories'),
                onBackPress: () async {
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 10),
              const DefaultSelectedCustomerWidget(),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3),
        child: Column(
          children: [
            const SizedBox(height: 6),
            searchAndFilterRow(),
            Expanded(
              child: FullVendorRefreshIndicator(
                refreshIndicatorKey: _refreshIndicatorKey,
                onRefresh: loadCategoryList,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 0, right: 0, top: 5),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 150,
                    ),
                    itemCount: _categoryListDataModel?.list
                            ?.where((element) => filterSearchBasedOnText(element))
                            .toList()
                            .length ??
                        0,
                    itemBuilder: (context, index) {
                      CategoryModel? categoryModel = _categoryListDataModel?.list
                          ?.where((element) => filterSearchBasedOnText(element))
                          .toList()[index];
                      if (categoryModel == null) return Container();
                      return optionWidget(
                        title: categoryModel.categoryName ?? '',
                        imagePath: categoryModel.images ?? '',
                        imageBlob: categoryModel.imageBlob,
                        onTap: () async {
                          await FullVendor.instance.pushNamed(
                            SalesmanProductPage.routeName,
                            parameters: categoryModel.categoryId ?? '',
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget searchAndFilterRow() {
    return Row(
      children: [
        Expanded(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: tr('search'),
                border: InputBorder.none,
                hintStyle: const TextStyle(color: appSecondaryColor, fontSize: 12),
                prefixIcon: const Icon(Icons.search, color: appSecondaryColor, size: 16),
                suffixIcon: const SizedBox(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          surfaceTintColor: appPrimaryLightColor,
          elevation: 2,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: PopupMenuButton<bool>(
            onSelected: (value) {
              sortAscending = value;
              _refreshIndicatorKey.currentState?.show();
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(value: true, child: Text(tr('ascending'))),
                PopupMenuItem(value: false, child: Text(tr('descending'))),
              ];
            },
            icon: const Icon(CupertinoIcons.arrow_up_arrow_down),
          ),
        ),
      ],
    );
  }

  Widget optionWidget({
    required String title,
    required String imagePath,
    Function()? onTap,
    Uint8List? imageBlob,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: onTap,
        radius: 10,
        splashColor: appPrimaryColor.withOpacity(0.9),
        highlightColor: appPrimaryColor.withOpacity(0.9),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 0),
            SizedBox(
              height: 50,
              width: 60,
              child: imageBlob != null
                  ? Image.memory(
                      imageBlob,
                      fit: BoxFit.contain,
                    )
                  : FullVendorCacheImageLoader(imageUrl: imagePath),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 0),
          ],
        ),
      ),
    );
  }

  bool filterSearchBasedOnText(CategoryModel categoryModel) {
    if (_searchText == null) return true;
    return categoryModel.categoryName?.toLowerCase().contains(_searchText!) ?? false;
  }

  Future<void> loadCategoryForDB() async {
    List<Map<String, dynamic>> list =
        await SyncedDB.instance.readCategoryList(order: sortAscending ? 'ASC' : 'DESC');
    _categoryListDataModel = CategoryListDataModel.fromJson({'list': list});

    // if (_categoryListDataModel?.list?.isEmpty ?? true) {
    //   await loadCategoryList();
    // }
    if (mounted) setState(() {});
  }

  Future<void> loadCategoryList() async {
    try {
      dynamic response = await Apis().categoryList();
      // print(jsonEncode(response));
      _categoryListDataModel = CategoryListDataModel.fromJson(response);
      if (_categoryListDataModel?.list?.isEmpty ?? true) {
        throw Exception('No category found');
      }
      if (!mounted) return;
      setState(() {});
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {});
    }

    await loadCategoryForDB();
    return;
  }
}
