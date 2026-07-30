import 'package:flutter/material.dart';

import 'package:gesture_os/core/constants/app_constants.dart';

/// Responsive utility for adapting layouts across screen sizes.
/// Uses MediaQuery to determine device type and provides
/// responsive values based on current screen dimensions.
enum DeviceType { mobile, tablet, desktop }

abstract final class Responsive {
  Responsive._();

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= AppConstants.mobileMaxWidth) return DeviceType.mobile;
    if (width <= AppConstants.tabletMaxWidth) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static double responsiveValue(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
        return desktop;
    }
  }

  static double scaleWidth(BuildContext context, double baseWidth) {
    final width = screenWidth(context);
    return baseWidth * (width / 390);
  }

  static double scaleFontSize(BuildContext context, double baseFontSize) {
    final width = screenWidth(context);
    final scale = (width / 390).clamp(0.85, 1.3);
    return baseFontSize * scale;
  }

  static double horizontalPadding(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 24,
      tablet: 48,
      desktop: 80,
    );
  }
}
