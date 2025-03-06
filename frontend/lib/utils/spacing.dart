import 'package:flutter/material.dart';

class VerticalSpacing extends EdgeInsets {
  const VerticalSpacing(double top, double bottom)
      : super.only(top: top, bottom: bottom);
}

class HorizontalSpacing extends EdgeInsets {
  const HorizontalSpacing(double left, double right)
      : super.only(left: left, right: right);
}
