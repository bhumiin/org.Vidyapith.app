import 'package:flutter/material.dart';

import 'logo_leading.dart';

PreferredSizeWidget buildBrandedAppBar({
  Widget? title,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
  Color? backgroundColor,
  double leadingWidth = 140,
}) {
  return AppBar(
    automaticallyImplyLeading: false,
    leading: const LogoLeading(),
    leadingWidth: leadingWidth,
    title: title,
    centerTitle: true,
    actions: actions,
    bottom: bottom,
    backgroundColor: backgroundColor,
  );
}


