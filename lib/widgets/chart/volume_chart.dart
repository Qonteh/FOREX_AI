import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/onboarding/onboarding_flow.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: OnboardingFlow(
          onComplete: () {
            context.go('/');
          },
        ),
      ),
    );
  }
}