import 'dart:async';

import 'package:FullVendor/network/apis.dart';
import 'package:FullVendor/screens/warehouse/warehouse_cart_page.dart';
import 'package:FullVendor/widgets/app_theme_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

import '../../application/application_global_keys.dart';
import '../../db/sql/cart_sql_helper.dart';
import '../../db/synced_db.dart';
import '../../model/category_data_model.dart';
import '../../model/product_list_data_model.dart';
import '../../widgets/products/product_view.dart';
import '../../widgets/refresh_indicator.dart';
import '../../widgets/salesman/salesman_fragment_header_widget.dart';
import '../../widgets/salesman/salesman_profile_widget.dart';
import '../../widgets/salesman/salesman_search_sort_filter_widget.dart';
import '../salesman/salesman_product_page.dart';

class WareHouseCreditPage extends StatefulWidget {
  const WareHouseCreditPage(
      {super.key, this.orderId, required this.isFromCart});
  static const String routeName = '/warehouse/credit-note';
  final String? orderId;
  final bool isFromCart;

  @override
  State<WareHouseCreditPage> createState() => _WareHouseCreditPageState();
}

class _WareHouseCreditPageState extends State<WareHouseCreditPage> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshController = GlobalKey();
  final ScrollController _categoryScrollController = ScrollController();
  CategoryListDataModel? _categoryListDataModel;
  ProductListDataModel? productListDataModel;
  int selectedCategory = 0;
  Timer? _timer;

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
      _timer = Timer(const Duration(seconds: 1), () async {
        await loadData();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _categoryScrollController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      appBar: Column(
        children: [
          SalesmanTopBar(
            title: widget.orderId != null
                ? tr('edit_order_with_arg', args: [widget.orderId ?? ''])
                : tr('credit_notes'),
            onBackPress: () async {
              Navigator.of(context).pop();
            },
          ),
          // const Divider(height: 0, thickness: 1),
          const SalesmanProfileWidget(),
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
      margin: const EdgeInsets.only(left: 10, right: 10, bottom: 0),
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
            onPressed: widget.orderId != null
                ? () {
                    Navigator.of(context).pop();
                  }
                : value == 0
                    ? null
                    : () async {
                        if (widget.isFromCart) {
                          Navigator.pop(context);
                          return;
                        }
                        await FullVendor.instance
                            .pushNamed(WarehouseCartPage.routeName);
                        if (!mounted) return;
                        _refreshController.currentState?.show();
                      },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined,
                        color: Colors.white),
                    const SizedBox(width: 10),
                    Text(tr('cart'),
                        style: const TextStyle(color: Colors.white)),
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
        child: productViewMode == ViewType.product
            ? productPageView()
            : productGridView(),
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
            productListDataModel?.list?.elementAt(index) ??
                ProductDetailsDataModel();
        return ProductPageElement(
          productDetailsDataModel: productDetailsDataModel,
          orderId: widget.orderId,
        );
      },
    );
  }

  Widget productGridView() {
    return CustomScrollView(
      key: ValueKey('$productViewMode'),
      slivers: [
        if (productViewMode == ViewType.grid)
          SliverGrid(
            key:
                ValueKey('gridView ${productListDataModel?.list?.length ?? 0}'),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                ProductDetailsDataModel productDetailsDataModel =
                    productListDataModel?.list?.elementAt(index) ??
                        ProductDetailsDataModel();
                return ProductGridElement(
                  productDetailsDataModel: productDetailsDataModel,
                  orderId: widget.orderId,
                );
              },
              childCount: productListDataModel?.list?.length ?? 0,
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.6,
            ),
          ),
        if (productViewMode == ViewType.list)
          SliverList(
            key:
                ValueKey('gridView ${productListDataModel?.list?.length ?? 0}'),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                ProductDetailsDataModel productDetailsDataModel =
                    productListDataModel?.list?.elementAt(index) ??
                        ProductDetailsDataModel();
                return ProductListElement(
                  productDetailsDataModel: productDetailsDataModel,
                  orderId: widget.orderId,
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
      scrollDirection: Axis.horizontal,
      controller: _categoryScrollController,
      child: Row(
        children: List.generate(
          _categoryListDataModel?.list?.length ?? 0,
          (index) {
            CategoryModel categoryModel =
                _categoryListDataModel?.list?.elementAt(index) ??
                    CategoryModel();
            GlobalKey object = GlobalKey();
            if (index == scrollToIndex) {
              Future.delayed(const Duration(milliseconds: 120), () {
                RenderBox? renderBox =
                    object.currentContext?.findRenderObject() as RenderBox?;
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
                RefreshIndicatorState refreshIndicatorState =
                    _refreshController.currentState!;
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
                    color: selectedCategory == index
                        ? const Color(0xFFCC2028)
                        : Colors.grey,
                  ),
                ),
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  categoryModel.categoryName ?? '',
                  style: TextStyle(
                    color: selectedCategory == index
                        ? const Color(0xFFCC2028)
                        : Colors.grey,
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
    if (_categoryListDataModel == null) {
      List<Map<String, dynamic>> list =
          await SyncedDB.instance.readCategoryList();
      _categoryListDataModel = CategoryListDataModel.fromJson({'list': list});
    }
    if (!mounted) return;
    setState(() {});
  }

  String get selectedCategoryId =>
      _categoryListDataModel?.list?.elementAt(selectedCategory).categoryId ??
      '';

  Future<void> loadProductsFromAPI() async {
    dynamic response = await Apis().loadWarehouseProductList(
      categoryId: selectedCategoryId,
      search: _searchController.text,
    );
    if (response is Map<String, dynamic>) {
      productListDataModel = ProductListDataModel.fromJson(response);
      if (mounted) setState(() {});
    }
  }

  Future<void> loadData() async {
    await loadCategory();
    String? categoryId = selectedCategoryId;
    try {
      await loadProductsFromAPI();
      return;
    } catch (e) {
      print(e);
    }
    List<Map<String, dynamic>> productList =
        await SyncedDB.instance.readProducts(
      categoryId: categoryId,
      search: _searchController.text,
    );

    productListDataModel = ProductListDataModel.fromJson({'list': productList});
    if (mounted) setState(() {});
  }
}
