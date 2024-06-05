import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../application/theme.dart';

class SearchWithOptionWidget extends StatelessWidget {
  const SearchWithOptionWidget({
    super.key,
    required this.searchController,
    required this.optionWidget,
  });
  final List<Widget> optionWidget;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: tr('search'),
                border: InputBorder.none,
                hintStyle:
                    const TextStyle(color: appSecondaryColor, fontSize: 12),
                prefixIcon: const Icon(
                  Icons.search,
                  color: appSecondaryColor,
                  size: 16,
                ),
                suffixIcon: const SizedBox(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        for (int i = 0; i < optionWidget.length; i++)
          optionSurroundingWidget(optionWidget[i]),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget optionSurroundingWidget(Widget widget) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      surfaceTintColor: appPrimaryLightColor,
      elevation: 2,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: widget,
    );
  }
}
