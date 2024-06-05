import 'package:flutter/material.dart';

const Color appPrimaryColor = Color(0xFFCC2028);
const Color appPrimaryLightColor = Color(0xFFFFE5E5);
const Color appSecondaryColor = Color(0xFF18254D);
const Color fragmentBackgroundColor = Colors.white;

const Gradient appPrimaryGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    appPrimaryColor,
    appSecondaryColor,
    appSecondaryColor,
  ],
);

const BorderRadius fragmentBorderRadius = BorderRadius.only(
  topLeft: Radius.circular(16),
  topRight: Radius.circular(16),
);

const BoxDecoration fragmentBoxDecoration = BoxDecoration(
  color: fragmentBackgroundColor,
  borderRadius: fragmentBorderRadius,
);
