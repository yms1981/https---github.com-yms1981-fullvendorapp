import 'dart:async';
import 'dart:convert';

import 'package:FullVendor/application/application_global_keys.dart';
import 'package:FullVendor/screens/salesman/salesman_cart_page.dart';
import 'package:FullVendor/widgets/app_theme_widget.dart';
import 'package:FullVendor/widgets/refresh_indicator.dart';
import 'package:FullVendor/widgets/salesman/salesman_profile_widget.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../db/sql/cart_sql_helper.dart';
import '../../db/synced_db.dart';
import '../../model/category_data_model.dart';
import '../../model/customer_list_data_model.dart';
import '../../model/product_list_data_model.dart';
import '../../network/apis.dart';
import '../../utils/extensions.dart';
import '../../widgets/products/product_view.dart';
import '../../widgets/salesman/salesman_fragment_header_widget.dart';
import '../../widgets/salesman/salesman_search_sort_filter_widget.dart';
import 'customer_selection_fragment.dart';

class SalesmanProductPage extends StatefulWidget {
  const SalesmanProductPage({super.key, this.categoryId});

  static const String routeName = '/salesman/product';
  final String? categoryId;

  @override
  State<SalesmanProductPage> createState() => _SalesmanProductPageState();
}

enum ViewType { list, grid, product }

ViewType productViewMode = ViewType.grid;

class _SalesmanProductPageState extends State<SalesmanProductPage> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshController = GlobalKey();
  final ScrollController _categoryScrollController = ScrollController();
  CategoryListDataModel? _categoryListDataModel;
  ProductListDataModel? productListDataModel;
  ProductListDataModel? allProductListDataModel;
  int selectedCategory = 0;
  Timer? _timer;
  StreamSubscription? _streamSubscription;

  final List<IconData> viewTypeIcons = [
    Icons.menu_rounded,
    CupertinoIcons.square_grid_2x2,
    Icons.credit_card,
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() async {
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 2), () async {
        _refreshController.currentState?.show();
      });
    });
    defaultCustomerNotifier.addListener(onNewCustomerSelected);
    loadingObserverOfAllProduct();
    _streamSubscription = Connectivity().onConnectivityChanged.listen((event) {
      if (event == ConnectivityResult.none) return;
      loadingObserverOfAllProduct();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _categoryScrollController.dispose();
    _timer?.cancel();
    _streamSubscription?.cancel();
    defaultCustomerNotifier.removeListener(onNewCustomerSelected);
    super.dispose();
  }

  Future<void> onNewCustomerSelected() async {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      appBar: Column(
        children: [
          SalesmanTopBar(
            title: tr('products'),
            onBackPress: () async {
              Navigator.of(context).pop();
            },
          ),
          SalesmanProfileWidget(
            onEditPress: () async {
              Customer? newSelectedCustomer =
                  await FullVendor.instance.pushNamed(CustomerSelectionFragment.routeName);
              if (newSelectedCustomer != null) {
                defaultCustomerNotifier.value = newSelectedCustomer;
                Fluttertoast.showToast(msg: tr('customer_changed'));
              }
              _refreshController.currentState?.show();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 6),
          searchAndFilterRow(),
          const SizedBox(height: 6),
          categoryRow(),
          const SizedBox(height: 6),
          Expanded(child: productView()),
        ],
      ),
      bottomNavigationBar: goToCartButton(),
    );
  }

  Widget goToCartButton() {
    return Container(
      margin: const EdgeInsets.only(
        left: 10,
        right: 10,
        bottom: 10,
        top: 5,
      ),
      constraints: const BoxConstraints(minHeight: 50),
      child: ValueListenableBuilder(
        valueListenable: cartQuantityNotifier,
        builder: (context, value, child) {
          return MaterialButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            disabledColor: Colors.grey,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: const Color(0xFFCC2028),
            onPressed: value == 0
                ? null
                : () async {
                    await FullVendor.instance.pushNamed(SalesmanCartPage.routeName);
                    if (!mounted) return;
                    _refreshController.currentState?.show();
                  },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(tr('cart'), style: const TextStyle(color: Colors.white)),
                  ],
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget productView() {
    return FullVendorRefreshIndicator(
      refreshIndicatorKey: _refreshController,
      onRefresh: loadData,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: animation.drive(
              Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero),
            ),
            child: child,
          );
        },
        child: productViewMode == ViewType.product ? productPageView() : productGridView(),
      ),
    );
  }

  Widget productPageView() {
    return PageView.builder(
      scrollDirection: Axis.horizontal,
      // key: ValueKey('pageView ${productListDataModel?.list?.length ?? 0}'),
      itemCount: productListDataModel?.list?.length ?? 0,
      itemBuilder: (context, index) {
        ProductDetailsDataModel productDetailsDataModel =
            productListDataModel?.list?.elementAt(index) ?? ProductDetailsDataModel();
        return ProductPageElement(
          productDetailsDataModel: productDetailsDataModel,
        );
      },
    );
  }

  double aspectRation = 0.6;

  Widget productGridView() {
    return CustomScrollView(
      key: ValueKey('$productViewMode'),
      slivers: [
        if (productViewMode == ViewType.grid)
          SliverGrid(
            key: ValueKey('gridView ${productListDataModel?.list?.length ?? 0}'),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                ProductDetailsDataModel productDetailsDataModel =
                    productListDataModel?.list?.elementAt(index) ?? ProductDetailsDataModel();
                return ProductGridElement(
                  productDetailsDataModel: productDetailsDataModel,
                );
              },
              childCount: productListDataModel?.list?.length ?? 0,
            ),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: aspectRation,
            ),
          ),
        if (productViewMode == ViewType.list)
          SliverList(
            key: ValueKey('gridView ${productListDataModel?.list?.length ?? 0}'),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                ProductDetailsDataModel productDetailsDataModel =
                    productListDataModel?.list?.elementAt(index) ?? ProductDetailsDataModel();
                return ProductListElement(
                  productDetailsDataModel: productDetailsDataModel,
                );
              },
              childCount: productListDataModel?.list?.length ?? 0,
            ),
          ),
      ],
    );
  }

  Widget searchAndFilterRow() {
    return SearchWithOptionWidget(
      searchController: _searchController,
      optionWidget: [
        IconButton(
          onPressed: () async {
            if (productViewMode == ViewType.list) {
              productViewMode = ViewType.grid;
            } else if (productViewMode == ViewType.grid) {
              productViewMode = ViewType.product;
            } else {
              productViewMode = ViewType.list;
            }
            setState(() {});
          },
          icon: Icon(viewTypeIcons[productViewMode.index], color: Colors.black),
        ),
        IconButton(
          onPressed: () async {
            String? barCodeResult = await FlutterBarcodeScanner.scanBarcode(
                '#ff6666', tr('cancel'), true, ScanMode.BARCODE);
            if (barCodeResult == "-1") return;
            _searchController.text = barCodeResult;
          },
          icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.black),
        ),
      ],
    );
  }

  int scrollToIndex = 0;

  Widget categoryRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _categoryScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: List.generate(
          _categoryListDataModel?.list?.length ?? 0,
          (index) {
            CategoryModel categoryModel =
                _categoryListDataModel?.list?.elementAt(index) ?? CategoryModel();
            GlobalKey object = GlobalKey();
            if (index == scrollToIndex) {
              Future.delayed(const Duration(milliseconds: 120), () {
                RenderBox? renderBox = object.currentContext?.findRenderObject() as RenderBox?;
                if (renderBox != null) {
                  _categoryScrollController.position.ensureVisible(
                    renderBox,
                    duration: const Duration(milliseconds: 220),
                  );
                }
                Future.delayed(const Duration(milliseconds: 220), () {
                  scrollToIndex = -1;
                });
              });
            }

            return InkWell(
              key: object,
              onTap: () async {
                selectedCategory = index;
                scrollToIndex = index;
                setState(() {});
                RefreshIndicatorState refreshIndicatorState = _refreshController.currentState!;
                // manually created function to material refresh indicator file
                //   Future<void> disposeRefresh() async {
                //     if (_mode == _RefreshIndicatorMode.refresh)
                //       await _dismiss(_RefreshIndicatorMode.done);
                //   }
                await refreshIndicatorState.disposeRefresh();
                await _refreshController.currentState?.show();
              },
              child: Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.only(left: 5.0, right: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: selectedCategory == index ? const Color(0xFFCC2028) : Colors.grey,
                  ),
                ),
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  categoryModel.categoryName ?? '',
                  style: TextStyle(
                    color: selectedCategory == index ? const Color(0xFFCC2028) : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> loadCategory() async {
    bool isFirst = _categoryListDataModel == null;
    if (isFirst) {
      try {
        dynamic response = await Apis().categoryList();
        _categoryListDataModel = CategoryListDataModel.fromJson(response);
      } catch (_) {}
      if (_categoryListDataModel?.list?.isEmpty ?? true) {
        List<Map<String, dynamic>> list = await SyncedDB.instance.readCategoryList();
        _categoryListDataModel = CategoryListDataModel.fromJson({'list': list});
      }
      CategoryModel? firstModelByCategoryId = _categoryListDataModel?.list?.firstWhere((element) {
        return element.categoryId == widget.categoryId;
      }, orElse: () => CategoryModel());
      if (firstModelByCategoryId?.categoryId != null) {
        selectedCategory = _categoryListDataModel?.list?.indexOf(firstModelByCategoryId!) ?? 0;
        scrollToIndex = selectedCategory;
      }
    }
    if (!mounted) return;
    setState(() {});
  }

  String get selectedCategoryId =>
      _categoryListDataModel?.list?.elementAtOrNull(selectedCategory)?.categoryId ?? '';

  Future<void> loadData() async {
    await loadCategory();
    try {
      await loadProducts(categoryId: selectedCategoryId);
      return;
    } catch (e) {
      print(e);
    }
    // todo api calling with search and category id
    // await loadAllProducts();
    String? categoryId = selectedCategoryId;
    List<Map<String, dynamic>> productList = await SyncedDB.instance.readProducts(
      categoryId: categoryId,
      search: _searchController.text.trim(),
    );

    productListDataModel = ProductListDataModel.fromJson({'list': productList});
    if (mounted) setState(() {});
  }

  Future<void> loadProducts({String? categoryId}) async {
    if (_searchController.text.trim().isNotEmpty) {
      if (allProductListDataModel == null) {
        String message = "All product not loaded yet, showing offline data";
        Fluttertoast.showToast(msg: message);
        throw Exception(message);
      }
      await productByQuery();
      return;
    }
    int currentTimeInMiliSec = DateTime.now().millisecondsSinceEpoch;
    dynamic response = await Apis().productList(categoryId: categoryId);
    int responeTimeInMilisec = DateTime.now().millisecondsSinceEpoch;
    int timeEClipsed = responeTimeInMilisec - currentTimeInMiliSec;
    print("Time eclipsed for category wise is in milisec is $timeEClipsed");
    if (response is String) {
      response = jsonDecode(response);
    }
    if (response['status'] == '0') {
      throw Exception(response['message'] ?? 'No products found');
    }
    productListDataModel = ProductListDataModel.fromJson(response);
    if (productListDataModel?.list?.isEmpty ?? true) {
      throw Exception('No products found');
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> loadingObserverOfAllProduct() async {
    try {
      await loadAllProductForSearchIn();
    } catch (e) {
      print("Loading failed with loading all product in back");
      print(e);
    }
  }

  Future<void> loadAllProductForSearchIn() async {
    if (allProductListDataModel != null) return;

    int currentTimeInMilliSec = DateTime.now().millisecondsSinceEpoch;
    dynamic response = await Apis().productList();
    int responseTimeInMilliSec = DateTime.now().millisecondsSinceEpoch;
    int timeEclipsed = responseTimeInMilliSec - currentTimeInMilliSec;
    print("Time eclipsed in milisec is $timeEclipsed");
    String message = "All product loaded in ";
    message += timeEclipsed > 1000 ? "${timeEclipsed / 1000} sec" : "$timeEclipsed milisec";
    Fluttertoast.showToast(msg: message);
    if (response is String) {
      response = jsonDecode(response);
    }
    if (response['status'] == '0') {
      return;
    }
    allProductListDataModel = ProductListDataModel.fromJson(response);
    if (allProductListDataModel?.list?.isEmpty ?? true) {
      allProductListDataModel = null;
    }
  }

  bool productMatchCondition(ProductDetailsDataModel element) {
    String query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) return false;

    var name = element.name?.toLowerCase() ?? '';
    var sku = element.sku?.toLowerCase() ?? '';
    var description = element.descriptions?.toLowerCase() ?? '';
    var tags = element.tags?.toLowerCase() ?? '';
    var barcode = element.barcode?.toLowerCase() ?? '';

    return name.contains(query) ||
        sku.contains(query) ||
        description.contains(query) ||
        tags.contains(query) ||
        barcode.contains(query);
  }

  Future<void> productByQuery() async {
    if (allProductListDataModel == null) return;
    String query = _searchController.text.trim();
    if (query.isEmpty) return;
    List<ProductDetailsDataModel> allProductList = allProductListDataModel?.list ?? [];
    List<ProductDetailsDataModel> filteredProductList =
        allProductList.where(productMatchCondition).toList();
    productListDataModel = ProductListDataModel(list: filteredProductList);
  }
}
