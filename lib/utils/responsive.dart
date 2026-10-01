import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width < 900 || size.height < 500;
  }

  static bool isDesktop(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width >= 900 && size.height >= 500;
  }

  static double maxWidth(BuildContext context) =>
      isDesktop(context) ? 1200 : double.infinity;
}
