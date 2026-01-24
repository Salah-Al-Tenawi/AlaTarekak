part of 'onboarding_cubit.dart';

abstract class OnboardingState {}

class OnboardingInitial extends OnboardingState {}

class OnboardingPageChanged extends OnboardingState {
  final int index;
  OnboardingPageChanged(this.index);
}

class OnboardingFinished extends OnboardingState {}
