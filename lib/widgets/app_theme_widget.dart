import 'package:FullVendor/utils/extensions.dart';
import 'package:flutter/material.dart';

import '../application/theme.dart';

class AppThemeWidget extends StatelessWidget {
  const AppThemeWidget({
    super.key,
    required this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.elevation = 0,
    this.flex = 1,
    this.useBottomPadding = true,
  });

  final Widget appBar;
  final Widget body;
  final int elevation;
  final Widget? bottomNavigationBar;
  final int flex;
  final bool useBottomPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: bottomNavigationBar != null
          ? bottomNavigationBar is BottomNavigationBar
              ? bottomNavigationBar
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    bottomNavigationBar!,
                    if (useBottomPadding)
                      SizedBox(
                        height: context.mediaQuery.padding.bottom / 1.5,
                        width: double.infinity,
                      ),
                  ],
                )
          : const SizedBox(),
      body: Container(
        decoration:
            const BoxDecoration(gradient: appPrimaryGradient, boxShadow: [
          BoxShadow(color: Colors.transparent),
        ]),
        child: SafeArea(
          child: Column(
            children: [
              appBar,
              if (flex == 0)
                const SizedBox(height: 0)
              else
                Expanded(
                  flex: flex,
                  child: Container(
                    decoration: BoxDecoration(
                      color: fragmentBackgroundColor,
                      borderRadius: fragmentBorderRadius,
                      boxShadow: elevation != 0
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                spreadRadius: 6,
                                blurRadius: 10,
                                offset: const Offset(0, 0),
                              )
                            ]
                          : null,
                    ),
                    margin: elevation != 0
                        ? const EdgeInsets.only(top: 0)
                        : const EdgeInsets.all(0),
                    child: body,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
