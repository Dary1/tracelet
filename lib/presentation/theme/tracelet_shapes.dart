import 'package:flutter/material.dart';

/// Corner radii and shape tokens.
abstract final class TraceletShapes {
  static const hardwareButtonRadius = 28.0;
  static const settingsFrameRadius = 24.0;
  static const buttonRadiusValue = 14.0;
  static const snackBarRadiusValue = 12.0;
  static const listTileRadiusValue = 12.0;

  static BorderRadius hardwareButtonA = const BorderRadius.only(
    topRight: Radius.circular(hardwareButtonRadius),
  );

  static BorderRadius hardwareButtonB = const BorderRadius.only(
    topLeft: Radius.circular(hardwareButtonRadius),
  );

  static BorderRadius buttonRadius = BorderRadius.circular(buttonRadiusValue);

  static BorderRadius snackBarRadius =
      BorderRadius.circular(snackBarRadiusValue);

  static BorderRadius listTileRadius =
      BorderRadius.circular(listTileRadiusValue);
}
