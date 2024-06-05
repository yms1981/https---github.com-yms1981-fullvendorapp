import 'package:FullVendor/application/theme.dart';
import 'package:FullVendor/utils/extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// function to dhow input bottom sheet for comment on product
/// returns null if user cancels the input or empty string if user clears the comment
/// returns the comment if user enters a comment
Future<String?> inputProductComment(
  BuildContext context,
  String? comment,
) async {
  return await showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return ProductCommentsWidget(oldComment: comment);
    },
  );
}

class ProductCommentsWidget extends StatefulWidget {
  const ProductCommentsWidget({super.key, this.oldComment});
  final String? oldComment;

  @override
  State<ProductCommentsWidget> createState() => _ProductCommentsWidgetState();
}

class _ProductCommentsWidgetState extends State<ProductCommentsWidget> {
  late TextEditingController _commentController;
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.oldComment);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _commentFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.mediaQuery.viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('comments'),
                  style: const TextStyle(
                      fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _commentController,
              focusNode: _commentFocusNode,
              decoration: InputDecoration(
                hintText: tr('add_comment'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              minLines: 3,
            ),
            const SizedBox(height: 16.0),
            MaterialButton(
              onPressed: () {
                // if (_commentController.text.isNotEmpty) {
                Navigator.pop(context, _commentController.text);
                // } else {
                //   Navigator.pop(context);
                // }
              },
              color: appPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              minWidth: double.infinity,
              height: 50,
              child: Text(
                tr('save'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// function to show custom quantity picker dialog of Cupertino style
Future<int?> showQuantityPicker(
  BuildContext context, {
  int? initialQuantity,
  int multiplier = 1,
}) async {
  return await showModalBottomSheet<int?>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(bottom: context.mediaQuery.viewInsets.bottom),
        child: QuantityPickerDialog(
          initialQuantity: initialQuantity,
          multiplier: multiplier,
        ),
      );
    },
  );
}

class QuantityPickerDialog extends StatefulWidget {
  const QuantityPickerDialog(
      {super.key, this.initialQuantity, this.multiplier = 1});
  final int? initialQuantity;
  final int multiplier;

  @override
  State<QuantityPickerDialog> createState() => _QuantityPickerDialogState();
}

class _QuantityPickerDialogState extends State<QuantityPickerDialog> {
  late List<int> _quantities;
  int _selectedIndex = 0;
  bool selectionMode = true;
  late TextEditingController _customQuantityController;
  final FocusNode _customQuantityFocusNode = FocusNode();

  @override
  void initState() {
    _customQuantityController =
        TextEditingController(text: widget.initialQuantity?.toString() ?? '0');
    int startFrom = 1;
    int endTo = 100;
    int skipCount = 0;
    if (widget.initialQuantity != null) {
      startFrom = widget.initialQuantity! - 50;
      if (startFrom < 1) {
        skipCount = startFrom.abs() + 1;
        startFrom = 0;
      }
      int step = 1;
      if (widget.multiplier > 1) {
        step = widget.multiplier;
      }
      endTo = widget.initialQuantity! + 50 + skipCount;
      _quantities = List<int>.generate(
        (endTo - startFrom) ~/ step,
        (index) => startFrom + (index * step),
      );
      _selectedIndex = _quantities.indexOf(widget.initialQuantity!);
      if (_selectedIndex == -1) {
        _selectedIndex = 0;
      }
    } else {
      _quantities = List<int>.generate(
        (endTo - startFrom) ~/ widget.multiplier,
        (index) => startFrom + (index * widget.multiplier),
      );
    }

    _customQuantityController.addListener(quantityListener);

    super.initState();
  }

  @override
  void dispose() {
    _customQuantityController.removeListener(quantityListener);
    _customQuantityController.dispose();
    super.dispose();
  }

  Future<void> quantityListener() async {
    int quantity = int.tryParse(_customQuantityController.text) ?? 0;
    if (quantity < 0) {
      _customQuantityController.text = '0';
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 16.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Text(tr('select_quantity'), style: TextStyle(fontSize: 18.0)),
              const Spacer(),
              Switch(
                value: selectionMode,
                onChanged: (value) {
                  selectionMode = value;
                  setState(() {});
                  if (value) {
                    _customQuantityFocusNode.unfocus();
                  } else {
                    _customQuantityFocusNode.requestFocus();
                  }
                },
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: const Offset(0, 0),
              ).animate(animation),
              child: child,
            );
          },
          duration: const Duration(milliseconds: 430),
          child: selectionMode
              ? SizedBox(
                  height: 200,
                  child: CupertinoPicker(
                    magnification: 1.22,
                    squeeze: 1.2,
                    useMagnifier: true,
                    itemExtent: 35,
                    scrollController: FixedExtentScrollController(
                        initialItem: _selectedIndex),
                    onSelectedItemChanged: (int selectedItem) {
                      setState(() {
                        _selectedIndex = selectedItem;
                      });
                    },
                    children: List<Widget>.generate(
                      _quantities.length,
                      (int index) {
                        return Center(
                            child: Text(_quantities[index].toString()));
                      },
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          int quantity =
                              int.tryParse(_customQuantityController.text) ?? 0;
                          if (quantity > 0) {
                            _customQuantityController.text =
                                (quantity - 1).toString();
                          }
                        },
                        icon: const Icon(Icons.remove),
                      ),
                      SizedBox(
                        width: 60,
                        height: 40,
                        child: TextField(
                          focusNode: _customQuantityFocusNode,
                          controller: _customQuantityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 8.0),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          int quantity =
                              int.tryParse(_customQuantityController.text) ?? 0;
                          _customQuantityController.text =
                              (quantity + 1).toString();
                        },
                        icon: const Icon(Icons.add),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: MaterialButton(
            onPressed: () async {
              dynamic value = selectionMode
                  ? _quantities[_selectedIndex]
                  : _customQuantityController.text;
              if (value is String) {
                value = int.tryParse(value) ?? 0;
              }
              if (value % widget.multiplier != 0) {
                Fluttertoast.showToast(
                    msg: tr('must_be_multiplication_of',
                        args: [widget.multiplier.toString()]));
                return;
              }
              Navigator.pop(context, value);
            },
            color: appPrimaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            minWidth: double.infinity,
            height: 50,
            child: Text(
              tr('update_quantity_to', args: [
                selectionMode
                    ? _quantities[_selectedIndex].toString()
                    : _customQuantityController.text
              ]),
              style: const TextStyle(color: Colors.white, fontSize: 16.0),
            ),
          ),
        ),
        const SizedBox(height: 5.0),
        SizedBox(height: context.mediaQuery.viewPadding.bottom)
      ],
    );
  }
}
