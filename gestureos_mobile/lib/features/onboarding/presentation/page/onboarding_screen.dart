import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gesture_os/app/router/route_names.dart';
import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/core/widgets/page_indicator.dart';
import 'package:gesture_os/shared/models/onboarding_data.dart';
import 'package:gesture_os/shared/providers/onboarding_provider.dart';
import 'package:gesture_os/features/onboarding/presentation/widgets/onboarding_page_content.dart';

/// Multi-page onboarding screen matching reference design exactly.
/// Layout: illustration top, title + description center, dots + buttons bottom.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    ref.read(onboardingProvider.notifier).goToPage(index);
  }

  void _onNextPressed() {
    final state = ref.read(onboardingProvider);
    if (state.isLastPage) {
      ref.read(onboardingProvider.notifier).completeOnboarding();
      context.goNamed(RouteNames.home);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onSkipPressed() {
    ref.read(onboardingProvider.notifier).completeOnboarding();
    context.goNamed(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Page View takes all available space
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: OnboardingData.pages.length,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return OnboardingPageContent(
                    data: OnboardingData.pages[index],
                  );
                },
              ),
            ),

            // Bottom section: indicator + buttons
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicator - centered
                  PageIndicator(
                    currentPage: state.currentPage,
                    totalPages: OnboardingData.pages.length,
                  ),

                  const SizedBox(height: 32),

                  // Skip (left) and Next (right) row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Skip button
                      GestureDetector(
                        onTap: _onSkipPressed,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),

                      // Next button
                      GestureDetector(
                        onTap: _onNextPressed,
                        child: Container(
                          width: 110,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              state.isLastPage ? 'Get Started' : 'Next',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
