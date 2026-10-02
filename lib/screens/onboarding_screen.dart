import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Onboarding — Phase 3',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
