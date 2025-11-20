import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.jpg',
      width: width,
      height: height,
      fit: fit,
    );
  }
}

class AppLogoWithText extends StatelessWidget {
  final double logoSize;
  final double fontSize;
  final Color? textColor;

  const AppLogoWithText({
    super.key,
    this.logoSize = 120,
    this.fontSize = 24,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(
          width: logoSize,
          height: logoSize * 0.6, // Maintain aspect ratio
        ),
        const SizedBox(height: 16),
        Text(
          'Quantis Trading',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: textColor ?? Theme.of(context).colorScheme.onBackground,
          ),
        ),
      ],
    );
  }
}