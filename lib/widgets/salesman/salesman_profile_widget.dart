import 'package:FullVendor/application/application_global_keys.dart';
import 'package:FullVendor/screens/salesman/customer_selection_fragment.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../generated/assets.dart';
import '../../model/customer_list_data_model.dart';
import '../../utils/extensions.dart';

class SalesmanProfileWidget extends StatelessWidget {
  const SalesmanProfileWidget({
    super.key,
    this.onEditPress,
  });
  // final String name;
  // final String shopName;
  final VoidCallback? onEditPress;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: defaultCustomerNotifier,
      builder: (context, value, child) {
        if (value == null) return const SizedBox();
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.2),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          padding: const EdgeInsets.all(10),
          child: InkWell(
            onTap: onEditPress ??
                () async {
                  Customer? newSelectedCustomer = await FullVendor.instance
                      .pushNamed(CustomerSelectionFragment.routeName);
                  if (newSelectedCustomer != null) {
                    defaultCustomerNotifier.value = newSelectedCustomer;
                    Fluttertoast.showToast(msg: tr('customer_changed'));
                  }
                },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  // crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(15),
                      child:
                          Image.asset(Assets.iconPerson, height: 35, width: 35),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value.businessName ?? "",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            value.name ?? "",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
