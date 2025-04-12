import 'package:flutter/material.dart';

class ScreenSizeService {
  static final ScreenSizeService _instance = ScreenSizeService._internal();
  factory ScreenSizeService() => _instance;
  ScreenSizeService._internal();

  late Size _screenSize;
  late double _scaleFactor;

  // Design size constants
  static const double DESIGN_WIDTH = 375.0;
  static const double DESIGN_HEIGHT = 812.0;

  void init(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;
    _scaleFactor = _screenSize.width / DESIGN_WIDTH;
  }

  double getScaledSize(double size) => size * _scaleFactor;

  double get screenWidth => _screenSize.width;
  double get screenHeight => _screenSize.height;

  // Responsive padding values
  EdgeInsets get defaultPadding => EdgeInsets.all(getScaledSize(16.0));
  EdgeInsets get cardPadding => EdgeInsets.all(getScaledSize(12.0));

  // Responsive sizes
  double get cardRadius => getScaledSize(12.0);
  double get buttonHeight => getScaledSize(48.0);
  double get iconSize => getScaledSize(24.0);
  double get titleFontSize => getScaledSize(20.0);
  double get bodyFontSize => getScaledSize(16.0);

  // Add these new methods
  double getProportionateScreenHeight(double inputHeight) {
    return (inputHeight / DESIGN_HEIGHT) * _screenSize.height;
  }

  double getProportionateScreenWidth(double inputWidth) {
    return (inputWidth / DESIGN_WIDTH) * _screenSize.width;
  }

  // Add these helper methods
  double get proportionateScreenHeight => _screenSize.height / 100;
  double get proportionateScreenWidth => _screenSize.width / 100;

  // Commonly used sizes
  double get defaultSpacing => getProportionateScreenHeight(20);
  double get smallSpacing => getProportionateScreenHeight(10);
  double get largeSpacing => getProportionateScreenHeight(30);
}
