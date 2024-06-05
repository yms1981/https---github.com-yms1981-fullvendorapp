import 'dart:typed_data';

import 'package:FullVendor/utils/extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../application/theme.dart';
import '../../db/sql/cart_sql_helper.dart';
import '../../model/product_list_data_model.dart';
import '../../model/warehouse_history_data_model.dart';
import '../../screens/warehouse/warehouse_order_details.dart';
import '../dialogs/product_dialogs.dart';
import '../full_vendor_cache_image_loader.dart';

/// widget that displays the single element of the product list.
/// This widget is used in [SalesmanProductPage] and [SalesmanCartPage]
/// [ProductListElementState] is used in the [SalesmanCartPage] for quantity
/// and delete functionality.
class ProductListElement extends StatefulWidget {
  const ProductListElement({
    super.key,
    required this.productDetailsDataModel,
    this.allowDelete = false,
    this.onAddToCart,
    this.orderId,
  });

  final ProductDetailsDataModel productDetailsDataModel;
  final bool allowDelete;
  final VoidCallback? onAddToCart;
  final String? orderId;

  @override
  State<ProductListElement> createState() => ProductListElementState();
}

/// State of the [ProductListElement] widget.
/// [ProductListElementState] is used in the [SalesmanCartPage] for quantity
/// and delete functionality.
class ProductListElementState extends State<ProductListElement> {
  String comment = '';

  @override
  void initState() {
    refreshQuantity();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    refreshQuantity();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    double discount = 0;
    if (defaultCustomerNotifier.value?.discount == null ||
        defaultCustomerNotifier.value?.discount == '') {
    } else {
      discount = double.parse(defaultCustomerNotifier.value?.discount ?? '0.0');
      discount = discount / 100;
    }

    // double salePrice =
    //     double.parse(widget.productDetailsDataModel.salePrice ?? '0.0');
    int minimumStock =
        double.parse(widget.productDetailsDataModel.minimumStock ?? '0').ceil();
    if (minimumStock < 1) minimumStock = 1;
    // double finalSalePrice = (salePrice + (salePrice * discount)) * minimumStock;
    // double priceAfterDiscount = finalSalePrice - (salePrice * minimumStock);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xffF8F8F8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      // margin: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black),
                ),
                constraints: const BoxConstraints(
                  minWidth: 100,
                  minHeight: 100,
                  maxWidth: 100,
                  maxHeight: 100,
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    widget.productDetailsDataModel.images?.firstOrNull
                                ?.imageBlob !=
                            null
                        ? Image.memory(
                            widget.productDetailsDataModel.images?.firstOrNull
                                    ?.imageBlob ??
                                Uint8List(0),
                            fit: BoxFit.fill,
                          )
                        : FullVendorCacheImageLoader(
                            imageUrl: widget.productDetailsDataModel.images
                                    ?.firstOrNull?.pic ??
                                '',
                          ),
                    if (widget.productDetailsDataModel.requested?.isNotEmpty ??
                        false)
                      const Positioned(
                        top: 0,
                        right: 0,
                        child: Icon(Icons.star, color: Colors.yellow),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: basicProductInfoColumn()),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // if (widget.productDetailsDataModel.quantity != 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () async {
                      if (widget.productDetailsDataModel.quantity == 0) {
                        Fluttertoast.showToast(msg: 'Please is not in cart');
                        return;
                      }
                      String? newComment =
                          await inputProductComment(context, comment);
                      if (newComment != null) {
                        comment = newComment;
                        await addButtonPrimaryAction();
                      }

                      if (!mounted) return;
                      setState(() {});
                    },
                    icon: Badge.count(
                      count: comment.isNotEmpty ? 1 : 0,
                      isLabelVisible:
                          widget.productDetailsDataModel.quantity != 0,
                      child: const Icon(Icons.message, color: appPrimaryColor),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              buttonAddToCart(),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget buttonAddToCart() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xffF8F8F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xffE5E5E5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: quantityDecreaseButton,
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () async {
                  int multiplier = widget.productDetailsDataModel.isForceMoq
                      ? widget.productDetailsDataModel.moq
                      : 1;
                  int? newQuantity = await showQuantityPicker(
                    context,
                    initialQuantity: widget.productDetailsDataModel.quantity,
                    multiplier: multiplier,
                  );
                  if (newQuantity != null) {
                    widget.productDetailsDataModel.quantity = newQuantity;
                    await addButtonPrimaryAction();
                    if (!mounted) return;
                    setState(() {});
                  }
                },
                child: Text(
                  '${widget.productDetailsDataModel.quantity}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: quantityIncreaseButton,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        if (!widget.allowDelete)
          MaterialButton(
            onPressed: moqQuantity,
            color: appPrimaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: const Row(
              children: [
                SizedBox(width: 5),
                Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  'MOQ',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
                SizedBox(width: 5),
              ],
            ),
          )
        else
          IconButton(
            onPressed: () async {
              if (widget.allowDelete) {
                await addToCart(widget.productDetailsDataModel, 0, '');
              }
              if (widget.onAddToCart != null) widget.onAddToCart!();
            },
            icon: const Icon(Icons.delete),
          )
      ],
    );
  }

  Widget basicProductInfoColumn() {
    Decimal discount = Decimal.parse(
        defaultCustomerNotifier.value?.percentPriceAmount ?? '0.0');
    bool increasePrice = defaultCustomerNotifier.value?.percentageOnPrice
            ?.toLowerCase()
            .contains("increase") ??
        true;
    discount = discount * Decimal.parse("0.01");
    Decimal salePrice =
        Decimal.parse(widget.productDetailsDataModel.salePrice ?? '0.0');
    int minimumStock =
        double.parse(widget.productDetailsDataModel.minimumStock ?? '0').ceil();
    if (minimumStock != 1) minimumStock = 1;
    Decimal discountPrice = Decimal.parse("0.0");
    if (increasePrice) {
      discountPrice = salePrice + (salePrice * discount);
    } else {
      discountPrice = salePrice - (salePrice * discount);
    }
    Decimal finalSalePrice =
        discountPrice * Decimal.parse(minimumStock.toString());
    // double priceAfterDiscount =
    //     (discountPrice - (salePrice * discount)) * minimumStock;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(height: 6),
        Text(
          "SKU: ${widget.productDetailsDataModel.sku ?? ''}",
          style: const TextStyle(color: Color(0xffCC2028), fontSize: 10),
        ),
        const SizedBox(height: 5),
        Text(
          widget.productDetailsDataModel.name ?? '',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text.rich(
          TextSpan(
            children: [
              // actual price
              TextSpan(
                text: "\$${finalSalePrice.toDecimalFormat()}",
                style: const TextStyle(
                  color: Color(0xffCC2028),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Text(
          'MOQ ${widget.productDetailsDataModel.moq}',
          style: const TextStyle(fontSize: 10, color: Color(0xffCC2028)),
        ),
        if (widget.productDetailsDataModel.lblstock?.isNotEmpty ?? false)
          Text(
            widget.productDetailsDataModel.lblstock ?? '',
            style: const TextStyle(fontSize: 10),
          ),
        const SizedBox(height: 5),
      ],
    );
  }

  Future<void> refreshQuantity() async {
    widget.productDetailsDataModel.quantity = await cartQuantityByProductId(
        widget.productDetailsDataModel.productId ?? '');
    if (!mounted) return;
    setState(() {});
    await loadComment();
  }

  Future<void> quantityDecreaseButton() async {
    double miniMumStock =
        double.parse(widget.productDetailsDataModel.minimumStock ?? '1');
    if (miniMumStock == 0) {
      miniMumStock = 1;
    }
    if (widget.productDetailsDataModel.quantity > miniMumStock.ceil()) {
      widget.productDetailsDataModel.quantity -= miniMumStock.ceil();
    } else {
      widget.productDetailsDataModel.quantity = 0;
    }
    if (widget.productDetailsDataModel.quantity < 0) {
      widget.productDetailsDataModel.quantity = 0;
    }
    if (!mounted) return;
    setState(() {});
    await addButtonPrimaryAction();
  }

  Future<void> quantityIncreaseButton() async {
    double miniMumStock =
        double.parse(widget.productDetailsDataModel.minimumStock ?? '1');
    if (miniMumStock == 0) {
      miniMumStock = 1;
    }
    widget.productDetailsDataModel.quantity += miniMumStock.ceil();
    setState(() {});
    await addButtonPrimaryAction();
  }

  Future<void> moqQuantity() async {
    double miniMumStock =
        double.parse(widget.productDetailsDataModel.minimumStock ?? '1');
    if (miniMumStock == 0) {
      miniMumStock = 1;
    }
    widget.productDetailsDataModel.quantity = miniMumStock.ceil();
    await addButtonPrimaryAction();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> addButtonPrimaryAction() async {
    if (widget.orderId != null) {
      await addOrUpdateProductToWarehouseOrder(
          widget.productDetailsDataModel, comment, widget.orderId);
      return;
    }
    bool isInCartOrNot =
        await isInCart(widget.productDetailsDataModel.productId ?? '');
    if (isInCartOrNot && widget.productDetailsDataModel.quantity == 0) {
      await removeFromCart(widget.productDetailsDataModel.toJson());
      Fluttertoast.showToast(msg: "Product removed from cart");
    } else if (widget.productDetailsDataModel.quantity > 0) {
      await addToCart(widget.productDetailsDataModel,
          widget.productDetailsDataModel.quantity, comment);
      Fluttertoast.showToast(msg: "Product quantity updated");
    } else {
      Fluttertoast.showToast(msg: 'Please add quantity');
    }
  }

  Future<void> loadComment() async {
    comment =
        await notesByProductId(widget.productDetailsDataModel.productId ?? '');
    if (!mounted) return;
    setState(() {});
  }
}

/// widget that displays the single element of the product grid.
/// This widget is used in [SalesmanProductPage]
class ProductGridElement extends StatefulWidget {
  const ProductGridElement({
    super.key,
    required this.productDetailsDataModel,
    this.orderId,
  });

  final String? orderId;

  final ProductDetailsDataModel productDetailsDataModel;

  @override
  State<ProductGridElement> createState() => _ProductGridElementState();
}

// todo replace cart quantity form on the image to else where
class _ProductGridElementState extends State<ProductGridElement> {
  String comment = '';

  @override
  void initState() {
    super.initState();
    refreshQuantity();
  }

  @override
  Widget build(BuildContext context) {
    Decimal discount = Decimal.parse(
        defaultCustomerNotifier.value?.percentPriceAmount ?? '0.0');
    bool increasePrice = defaultCustomerNotifier.value?.percentageOnPrice
            ?.toLowerCase()
            .contains("increase") ??
        true;
    discount = discount * Decimal.parse("0.01");
    Decimal salePrice =
        Decimal.parse(widget.productDetailsDataModel.salePrice ?? '0.0');
    int minimumStock =
        double.parse(widget.productDetailsDataModel.minimumStock ?? '0').ceil();
    if (minimumStock != 1) minimumStock = 1;
    Decimal discountPrice = Decimal.parse("0.0");
    if (increasePrice) {
      discountPrice = salePrice + (salePrice * discount);
    } else {
      discountPrice = salePrice - (salePrice * discount);
    }
    Decimal finalSalePrice =
        discountPrice * Decimal.parse(minimumStock.toString());
    // double priceAfterDiscount =
    //     (discountPrice - (salePrice * discount)) * minimumStock;
    return Container(
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffE0E0E0)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 180,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: widget.productDetailsDataModel.images?.firstOrNull
                              ?.imageBlob !=
                          null
                      ? Image.memory(
                          widget.productDetailsDataModel.images?.firstOrNull
                                  ?.imageBlob ??
                              Uint8List(0),
                          fit: BoxFit.fill,
                        )
                      : FullVendorCacheImageLoader(
                          imageUrl: widget.productDetailsDataModel.images
                                  ?.firstOrNull?.pic ??
                              '',
                          fit: BoxFit.fill,
                        ),
                ),
              ),
              if (widget.productDetailsDataModel.requested?.isNotEmpty ?? false)
                const Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(Icons.star, color: Colors.yellow),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                left: 0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: widget.productDetailsDataModel.quantity != 0
                        ? Colors.black.withOpacity(0.4)
                        : Colors.transparent,
                  ),
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: 5,
                    bottom: 5,
                  ),
                  child: _actionButtonWidget(),
                ),
              )
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'SKU:${widget.productDetailsDataModel.sku}',
                    style: const TextStyle(
                      color: Color(0xFFCC2028),
                      fontSize: 10,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: AutoSizeText(
                      '${widget.productDetailsDataModel.name}',
                      maxFontSize: 16,
                      minFontSize: 9,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: AutoSizeText(
                    '\$${finalSalePrice.toDecimalFormat()}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxFontSize: 24,
                    minFontSize: 14,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: AutoSizeText(
                    'MOQ ${widget.productDetailsDataModel.moq}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFCC2028),
                    ),
                    maxFontSize: 16,
                    minFontSize: 14,
                  ),
                ),
                if (widget.productDetailsDataModel.lblstock?.isNotEmpty ??
                    false)
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 8.0, bottom: 8, right: 8),
                    child: Text(
                      widget.productDetailsDataModel.lblstock ?? '',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtonWidget() {
    return Column(
      children: [
        AnimatedContainer(
          height: widget.productDetailsDataModel.quantity != 0 ? 45 : 0,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 3),
          duration: const Duration(milliseconds: 130),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: quantityDecreaseButton,
                icon: const Icon(Icons.remove, color: appPrimaryColor),
              ),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    int multiplier = widget.productDetailsDataModel.isForceMoq
                        ? widget.productDetailsDataModel.moq
                        : 1;
                    int? newQuantity = await showQuantityPicker(
                      context,
                      initialQuantity: widget.productDetailsDataModel.quantity,
                      multiplier: multiplier,
                    );
                    if (newQuantity != null) {
                      widget.productDetailsDataModel.quantity = newQuantity;
                      await addButtonPrimaryAction();
                      if (!mounted) return;
                      setState(() {});
                    }
                  },
                  child: Text(
                    '${widget.productDetailsDataModel.quantity}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              IconButton(
                onPressed: quantityIncreaseButton,
                icon: const Icon(Icons.add, color: appPrimaryColor),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () async {
                if (widget.productDetailsDataModel.quantity == 0) {
                  Fluttertoast.showToast(msg: 'Please is not in cart');
                  return;
                }
                String? newComment =
                    await inputProductComment(context, comment);
                if (newComment != null) {
                  comment = newComment;
                  await addButtonPrimaryAction();
                }
                if (!mounted) return;
                setState(() {});
              },
              icon: Badge.count(
                count: comment.isNotEmpty ? 1 : 0,
                isLabelVisible: widget.productDetailsDataModel.quantity != 0,
                child: Icon(
                  Icons.message,
                  color: widget.productDetailsDataModel.quantity == 0
                      ? appPrimaryColor
                      : Colors.white,
                ),
              ),
            ),
            MaterialButton(
              onPressed: moqQuantity,
              color: appPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              height: 0,
              minWidth: 0,
              child: const Icon(
                Icons.add_shopping_cart_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> quantityDecreaseButton() async {
    if (widget.productDetailsDataModel.quantity >
        widget.productDetailsDataModel.moq) {
      widget.productDetailsDataModel.quantity -=
          widget.productDetailsDataModel.moq;
    } else {
      widget.productDetailsDataModel.quantity = 0;
    }
    if (widget.productDetailsDataModel.quantity < 0) {
      widget.productDetailsDataModel.quantity = 0;
    }
    await addButtonPrimaryAction();
    setState(() {});
  }

  Future<void> quantityIncreaseButton() async {
    double miniMumStock =
        double.parse(widget.productDetailsDataModel.minimumStock ?? '1');
    if (miniMumStock == 0) {
      miniMumStock = 1;
    }
    widget.productDetailsDataModel.quantity +=
        widget.productDetailsDataModel.moq;
    setState(() {});
    await addButtonPrimaryAction();
  }

  Future<void> addButtonPrimaryAction() async {
    if (widget.orderId != null) {
      await addOrUpdateProductToWarehouseOrder(
          widget.productDetailsDataModel, comment, widget.orderId);
      return;
    }
    bool isInCartOrNot =
        await isInCart(widget.productDetailsDataModel.productId ?? '');
    if (isInCartOrNot && widget.productDetailsDataModel.quantity == 0) {
      await removeFromCart(widget.productDetailsDataModel.toJson());
      Fluttertoast.showToast(msg: "Product removed from cart");
    } else if (widget.productDetailsDataModel.quantity > 0) {
      await addToCart(widget.productDetailsDataModel,
          widget.productDetailsDataModel.quantity, comment);
      Fluttertoast.showToast(msg: "Product quantity updated");
    } else {
      await quantityIncreaseButton();
      await addButtonPrimaryAction();
    }
  }

  Future<void> moqQuantity() async {
    widget.productDetailsDataModel.quantity =
        widget.productDetailsDataModel.moq;
    await addButtonPrimaryAction();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> refreshQuantity() async {
    widget.productDetailsDataModel.quantity = await cartQuantityByProductId(
        widget.productDetailsDataModel.productId ?? '');
    if (!mounted) return;
    setState(() {});
    await loadComment();
  }

  Future<void> loadComment() async {
    comment =
        await notesByProductId(widget.productDetailsDataModel.productId ?? '');
    if (!mounted) return;
    setState(() {});
  }
}

class ProductPageElement extends StatefulWidget {
  const ProductPageElement({
    super.key,
    required this.productDetailsDataModel,
    this.orderId,
  });

  final String? orderId;

  final ProductDetailsDataModel productDetailsDataModel;

  @override
  State<ProductPageElement> createState() => _ProductPageElementState();
}

class _ProductPageElementState extends State<ProductPageElement> {
  String comment = '';

  @override
  void initState() {
    super.initState();
    refreshQuantity();
  }

  @override
  Widget build(BuildContext context) {
    Decimal discount = Decimal.parse(
        defaultCustomerNotifier.value?.percentPriceAmount ?? '0.0');
    bool increasePrice = defaultCustomerNotifier.value?.percentageOnPrice
            ?.toLowerCase()
            .contains("increase") ??
        true;
    discount = discount * Decimal.parse("0.01");
    Decimal salePrice =
        Decimal.parse(widget.productDetailsDataModel.salePrice ?? '0.0');
    int minimumStock =
        double.parse(widget.productDetailsDataModel.minimumStock ?? '0').ceil();
    if (minimumStock != 1) minimumStock = 1;
    Decimal discountPrice = Decimal.parse("0.0");
    if (increasePrice) {
      discountPrice = salePrice + (salePrice * discount);
    } else {
      discountPrice = salePrice - (salePrice * discount);
    }
    Decimal finalSalePrice =
        discountPrice * Decimal.parse(minimumStock.toString());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  widget.productDetailsDataModel.images?.firstOrNull
                              ?.imageBlob !=
                          null
                      ? Image.memory(
                          widget.productDetailsDataModel.images?.firstOrNull
                                  ?.imageBlob ??
                              Uint8List(0),
                          fit: BoxFit.fitWidth,
                        )
                      : FullVendorCacheImageLoader(
                          imageUrl: widget.productDetailsDataModel.images
                                  ?.firstOrNull?.pic ??
                              '',
                          fit: BoxFit.fill,
                        ),
                  if (widget.productDetailsDataModel.requested?.isNotEmpty ??
                      false)
                    const Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(Icons.star, color: Colors.yellow),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Divider(height: 1),
          Text(
            'SKU:${widget.productDetailsDataModel.sku}',
            style: const TextStyle(
              color: Color(0xFFCC2028),
              fontSize: 14,
            ),
          ),
          Text(
            '${widget.productDetailsDataModel.name}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            '\$${finalSalePrice.toDecimalFormat()}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          Text(
            'MOQ ${widget.productDetailsDataModel.moq}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFCC2028),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () async {
                  if (widget.productDetailsDataModel.quantity == 0) {
                    Fluttertoast.showToast(msg: 'Please is not in cart');
                    return;
                  }
                  String? newComment =
                      await inputProductComment(context, comment);
                  if (newComment != null) {
                    comment = newComment;
                    await addButtonPrimaryAction();
                  }

                  if (!mounted) return;
                  setState(() {});
                },
                icon: Badge.count(
                  count: comment.isNotEmpty ? 1 : 0,
                  isLabelVisible: widget.productDetailsDataModel.quantity != 0,
                  child: const Icon(Icons.message, color: appPrimaryColor),
                ),
              ),
              const Spacer(),
              Row(
                // mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xffF8F8F8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xffE5E5E5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: quantityDecreaseButton,
                          icon: const Icon(Icons.remove),
                        ),
                        InkWell(
                          onTap: () async {
                            int multiplier =
                                widget.productDetailsDataModel.isForceMoq
                                    ? widget.productDetailsDataModel.moq
                                    : 1;
                            int? newQuantity = await showQuantityPicker(
                              context,
                              initialQuantity:
                                  widget.productDetailsDataModel.quantity,
                              multiplier: multiplier,
                            );
                            if (newQuantity != null) {
                              widget.productDetailsDataModel.quantity =
                                  newQuantity;
                              await addButtonPrimaryAction();
                              if (!mounted) return;
                              setState(() {});
                            }
                          },
                          child: Text(
                            '${widget.productDetailsDataModel.quantity}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          onPressed: quantityIncreaseButton,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  MaterialButton(
                    onPressed: moqQuantity,
                    color: appPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: const Row(
                      children: [
                        SizedBox(width: 5),
                        Icon(
                          Icons.add_shopping_cart_rounded,
                          color: Colors.white,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'MOQ',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                        SizedBox(width: 5),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Future<void> quantityDecreaseButton() async {
    if (widget.productDetailsDataModel.quantity >
        widget.productDetailsDataModel.moq) {
      widget.productDetailsDataModel.quantity -=
          widget.productDetailsDataModel.moq;
    } else {
      widget.productDetailsDataModel.quantity = 0;
    }
    if (widget.productDetailsDataModel.quantity < 0) {
      widget.productDetailsDataModel.quantity = 0;
    }
    await addButtonPrimaryAction();
    setState(() {});
  }

  Future<void> quantityIncreaseButton() async {
    widget.productDetailsDataModel.quantity +=
        widget.productDetailsDataModel.moq;
    setState(() {});
    await addButtonPrimaryAction();
  }

  Future<void> addButtonPrimaryAction() async {
    if (widget.orderId != null) {
      await addOrUpdateProductToWarehouseOrder(
          widget.productDetailsDataModel, comment, widget.orderId);
      return;
    }
    bool isInCartOrNot =
        await isInCart(widget.productDetailsDataModel.productId ?? '');
    if (isInCartOrNot && widget.productDetailsDataModel.quantity == 0) {
      await removeFromCart(widget.productDetailsDataModel.toJson());
      Fluttertoast.showToast(msg: "Product removed from cart");
    } else if (widget.productDetailsDataModel.quantity > 0) {
      await addToCart(
        widget.productDetailsDataModel,
        widget.productDetailsDataModel.quantity,
        comment,
      );
      Fluttertoast.showToast(msg: "Product quantity updated");
    } else {
      Fluttertoast.showToast(msg: 'Please add quantity');
    }
  }

  Future<void> moqQuantity() async {
    widget.productDetailsDataModel.quantity =
        widget.productDetailsDataModel.moq;
    await addButtonPrimaryAction();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> refreshQuantity() async {
    widget.productDetailsDataModel.quantity = await cartQuantityByProductId(
        widget.productDetailsDataModel.productId ?? '');
    if (!mounted) return;
    setState(() {});
    await loadComment();
  }

  Future<void> loadComment() async {
    comment =
        await notesByProductId(widget.productDetailsDataModel.productId ?? '');
    if (!mounted) return;
    setState(() {});
  }
}

/// function to handle the add product to warehouse order
/// if orderId is not null then it will add or update the product to the warehouse order
Future<void> addOrUpdateProductToWarehouseOrder(
    ProductDetailsDataModel product, String comment, String? orderId) async {
  if (orderId == null) return;
  try {
    var list = WarehouseOrderDetailsPage.addedProduct?.value ?? [];
    var indexedProduct = list.firstWhere(
      (element) => (element.productId == product.productId),
      orElse: () {
        ProductList productList = ProductList();
        productList.productId = product.productId;
        productList.salePrice = product.salePrice;
        productList.comment = comment;
        return productList;
      },
    );
    indexedProduct.qty = product.quantity.toString();
    var index = list.indexOf(indexedProduct);
    if (index == -1) {
      list.add(indexedProduct);
    } else {
      list[index] = indexedProduct;
    }
    return;
  } catch (_) {}
}
