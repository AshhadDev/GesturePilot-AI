import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gesture_os/core/constants/app_constants.dart';

/// State notifier managing the current onboarding page index.
/// Uses immutable state with [OnboardingState].
class OnboardingState {
  const OnboardingState({
    this.currentPage = 0,
    this.isCompleted = false,
  });

  final int currentPage;
  final bool isCompleted;

  OnboardingState copyWith({
    int? currentPage,
    bool? isCompleted,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  bool get isFirstPage => currentPage == 0;
  bool get isLastPage => currentPage == AppConstants.onboardingPageCount - 1;
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

  void nextPage() {
    if (!state.isLastPage) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  void previousPage() {
    if (!state.isFirstPage) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  void goToPage(int page) {
    if (page >= 0 && page < AppConstants.onboardingPageCount) {
      state = state.copyWith(currentPage: page);
    }
  }

  void completeOnboarding() {
    state = state.copyWith(isCompleted: true);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});
