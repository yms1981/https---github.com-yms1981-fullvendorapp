import 'package:FullVendor/application/theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../application/application_global_keys.dart';
import '../../model/customer_list_data_model.dart';
import '../../screens/salesman/customer_selection_fragment.dart';
import '../../utils/extensions.dart';

Future<bool> checkIsCustomerSelected(BuildContext context) async {
  final Customer? customer = defaultCustomerNotifier.value;
  if (customer == null) {
    await showDialog(
      context: context,
      builder: (context) => const NoCustomerSelectedDialog(),
    );
  }
  return defaultCustomerNotifier.value != null;
}

class NoCustomerSelectedDialog extends StatefulWidget {
  const NoCustomerSelectedDialog({super.key});

  @override
  State<NoCustomerSelectedDialog> createState() =>
      _NoCustomerSelectedDialogState();
}

class _NoCustomerSelectedDialogState extends State<NoCustomerSelectedDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('no_customer_selected')),
      titleTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      content: Text(tr('please_select_customer')),
      contentTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 14,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(tr('dismiss')),
        ),
        MaterialButton(
          color: appPrimaryColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textColor: Colors.white,
          onPressed: () async {
            dynamic response = await FullVendor.instance
                .pushNamed(CustomerSelectionFragment.routeName);
            if (!mounted) return;
            if (response != null) {
              defaultCustomerNotifier.value = response;
              Navigator.of(context).pop(true);
            }
          },
          child: Text(tr('select_customer')),
        ),
      ],
    );
  }
}
