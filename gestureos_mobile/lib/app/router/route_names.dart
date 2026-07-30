/// Route name constants for GoRouter navigation.
abstract final class RouteNames {
  RouteNames._();

  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String home = 'home';
  static const String fileSelection = 'file_selection';
  static const String magicTransfer = 'magic_transfer';
  static const String carrying = 'carrying';
  static const String waitingDesktop = 'waiting_desktop';
  static const String transferProgress = 'transfer_progress';
  static const String receiver = 'receiver';
  static const String transferSuccess = 'transfer_success';
  static const String devices = 'devices';
  static const String settings = 'settings';
  static const String performanceDashboard = 'performance_dashboard';
  static const String transferHistory = 'transfer_history';
  static const String pairing = 'pairing';
  static const String deviceDetail = 'device_detail';
}

/// Route path constants for GoRouter navigation.
abstract final class RoutePaths {
  RoutePaths._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String fileSelection = '/file-selection';
  static const String magicTransfer = '/magic-transfer';
  static const String carrying = '/carrying';
  static const String waitingDesktop = '/waiting-desktop';
  static const String transferProgress = '/transfer-progress';
  static const String receiver = '/receiver';
  static const String transferSuccess = '/transfer-success';
  static const String devices = '/devices';
  static const String settings = '/settings';
  static const String performanceDashboard = '/performance';
  static const String transferHistory = '/history';
  static const String pairing = '/pairing/:deviceId/:deviceName/:deviceIp/:devicePlatform';
  static const String deviceDetail = '/device/:deviceId/:deviceName/:deviceIp/:devicePlatform/:devicePort/:isTrusted';
}
