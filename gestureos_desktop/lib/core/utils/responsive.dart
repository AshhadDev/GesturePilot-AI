import 'package:flutter/material.dart';

enum ScreenSize { small, medium, large }

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.small,
    required this.medium,
    required this.large,
  });

  final Widget small;
  final Widget medium;
  final Widget large;

  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 1280) return ScreenSize.small;
    if (width < 1600) return ScreenSize.medium;
    return ScreenSize.large;
  }

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1280) return small;
        if (constraints.maxWidth < 1600) return medium;
        return large;
      },
    );
  }
}

extension ResponsiveContext on BuildContext {
  ScreenSize get screenSize => ResponsiveLayout.getScreenSize(this);
  double get screenWidth => ResponsiveLayout.screenWidth(this);
  double get screenHeight => ResponsiveLayout.screenHeight(this);
  bool get isSmall => screenSize == ScreenSize.small;
  bool get isMedium => screenSize == ScreenSize.medium;
  bool get isLarge => screenSize == ScreenSize.large;
}
