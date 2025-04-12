import 'package:flutter/material.dart';
import '../services/screen_size_service.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Decoration? decoration;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.decoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width != null
          ? ScreenSizeService.getProportionateScreenWidth(width!)
          : null,
      height: height != null
          ? ScreenSizeService.getProportionateScreenHeight(height!)
          : null,
      padding: padding,
      margin: margin,
      decoration: decoration,
      child: child,
    );
  }
}
