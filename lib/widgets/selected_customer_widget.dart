import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../application/theme.dart';
import '../model/customer_list_data_model.dart';
import '../utils/extensions.dart';

class DefaultSelectedCustomerWidget extends StatelessWidget {
  const DefaultSelectedCustomerWidget({
    super.key,
    this.showLocation = true,
    this.showProfileImage = true,
  });
  final bool showLocation;
  final bool showProfileImage;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: defaultCustomerNotifier,
      builder: (context, value, child) {
        if (value == null) {
          return const SizedBox();
        }
        Customer customer = value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0x33F8F8F8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: InkWell(
            radius: 8,
            child: Column(
              children: [
                Row(
                  children: [
                    if (showProfileImage)
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(
                              color: Color(0xFFE5E5E5), width: 1),
                        ),
                        elevation: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            CupertinoIcons.person_alt_circle_fill,
                            color: appPrimaryColor,
                            size: 36,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name ?? '',
                            style: context.appTextTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            customer.businessName ?? "",
                            style: context.appTextTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (showLocation)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFFC8C8C8),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(
                        customer.commercialAddress ?? "",
                        style: context.appTextTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      )),
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
