import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: controller.skipOnboarding,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: PageView(
        onPageChanged: controller.onPageChanged,
        children: [
          const _OnboardingPage(
            title: 'Track Your Budget',
            description: 'Keep track of your income and expenses with ease',
            image: 'assets/images/onboarding/budget.png',
          ),
          const _OnboardingPage(
            title: 'Set Financial Goals',
            description: 'Plan and achieve your financial goals',
            image: 'assets/images/onboarding/goals.png',
          ),
          _OnboardingPage(
            title: 'Analyze Spending',
            description: 'Get insights into your spending habits',
            image: 'assets/images/onboarding/analysis.png',
            showGetStarted: true,
            onGetStarted: () => Get.find<OnboardingController>().completeOnboarding(),
          ),
        ],
      ),
      bottomNavigationBar: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: controller.currentPage.value == index
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String image;
  final bool showGetStarted;
  final VoidCallback? onGetStarted;

  const _OnboardingPage({
    Key? key,
    required this.title,
    required this.description,
    required this.image,
    this.showGetStarted = false,
    this.onGetStarted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            image,
            height: 240,
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (showGetStarted) ...[
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onGetStarted ?? controller.completeOnboarding,
              child: const Text('Get Started'),
            ),
          ],
        ],
      ),
    );
  }
}
