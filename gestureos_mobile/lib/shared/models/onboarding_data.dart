/// Immutable data model representing a single onboarding page.
class OnboardingData {
  const OnboardingData({
    required this.titleLines,
    required this.purpleWord,
    required this.description,
    required this.svgAsset,
  });

  final List<String> titleLines;
  final String purpleWord;
  final String description;
  final String svgAsset;

  static const List<OnboardingData> pages = [
    OnboardingData(
      titleLines: ['Control', 'Everything', 'Naturally'],
      purpleWord: 'Naturally',
      description: 'Use hand gestures to navigate, control\nand get things done.',
      svgAsset: 'assets/icons/hand_gesture.svg',
    ),
    OnboardingData(
      titleLines: ['Transfer', 'Files', 'Instantly'],
      purpleWord: 'Instantly',
      description: 'Share files between devices with\na simple gesture. Fast and secure.',
      svgAsset: 'assets/icons/file_transfer.svg',
    ),
    OnboardingData(
      titleLines: ['Smart', 'Gesture', 'Productivity'],
      purpleWord: 'Productivity',
      description: 'Boost your workflow with intelligent\ngesture-powered shortcuts.',
      svgAsset: 'assets/icons/smart_productivity.svg',
    ),
  ];
}
