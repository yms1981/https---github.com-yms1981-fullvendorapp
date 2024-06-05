import 'package:FullVendor/application/theme.dart';
import 'package:FullVendor/utils/extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// function to show dialog to confirm discard
/// the cart items
Future<bool> confirmCartDiscard(
  BuildContext context, {
  String? message,
}) async {
  bool? isDiscard = await showModalBottomSheet<bool?>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return ConfirmDiscardWidget(message: message);
    },
  );
  return isDiscard ?? false;
}

class ConfirmDiscardWidget extends StatefulWidget {
  const ConfirmDiscardWidget({super.key, this.message});
  final String? message;

  @override
  State<ConfirmDiscardWidget> createState() => _ConfirmDiscardWidgetState();
}

class _ConfirmDiscardWidgetState extends State<ConfirmDiscardWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(
            tr('confirm_discard_cart_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            widget.message ?? tr('confirm_discard_message'),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: MaterialButton(
                  height: 40,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text(tr('no')),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MaterialButton(
                  height: 40,
                  color: appPrimaryColor,
                  textColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text(tr('yes')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: context.mediaQuery.viewPadding.bottom)
        ],
      ),
    );
  }
}
