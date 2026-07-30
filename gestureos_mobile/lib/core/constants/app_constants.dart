/// Application-wide string and numeric constants.
abstract final class AppConstants {
  AppConstants._();

  // ── App Info ──
  static const String appName = 'GestureOS';
  static const String appTagline = 'Gesture-Powered Productivity';

  // ── Onboarding ──
  static const int onboardingPageCount = 3;
  static const Duration splashDuration = Duration(milliseconds: 2500);
  static const Duration onboardingTransitionDuration = Duration(milliseconds: 600);

  // ── Responsive Breakpoints ──
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;
  static const double desktopMaxWidth = 1440;

  // ── Asset Paths ──
  static const String logoPath = 'assets/icons/logo.png';

  // ── Animation Names ──
  static const String heroLogo = 'hero-logo';
}
