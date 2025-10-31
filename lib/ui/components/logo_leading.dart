import 'package:flutter/material.dart';

class LogoLeading extends StatelessWidget {
  const LogoLeading({
    super.key,
    this.logoHeight = 40,
    this.showBackButton,
  });

  final double logoHeight;
  final bool? showBackButton;

  @override
  Widget build(BuildContext context) {
    final shouldShowBackButton = showBackButton ?? Navigator.of(context).canPop();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (shouldShowBackButton) const BackButton(),
        Padding(
          padding: EdgeInsets.only(left: shouldShowBackButton ? 4.0 : 0.0),
          child: Image.asset(
            'assets/images/logo.png',
            height: logoHeight,
            fit: BoxFit.contain,
            semanticLabel: 'Vidyapith logo',
          ),
        ),
      ],
    );
  }
}


