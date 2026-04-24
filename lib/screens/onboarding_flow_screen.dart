import 'package:flutter/material.dart';
import 'package:museamigo/app_routes.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();

  final List<_OnboardingData> _slides = const [
    _OnboardingData(
      title: 'Meet Ogima',
      description: 'Your AI companion for every MuseAmigo discovery.',
    ),
    _OnboardingData(
      title: 'What I do',
      description:
          'I unlock hidden stories, explain artifacts, and navigate your museum journey.',
    ),
    _OnboardingData(
      title: 'How to start',
      description: 'Pick a museum, grab a ticket, and I\'ll see you there!',
    ),
  ];

  int _currentPage = 0;

  void _goToMapScreen() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.exploreMap, (route) => false);
  }

  void _next() {
    if (_currentPage == _slides.length - 1) {
      _goToMapScreen();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _goToMapScreen,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.blueGrey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (_, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 170,
                          child: InteractiveViewer(
                            panEnabled: false,
                            scaleEnabled: true,
                            minScale: 1,
                            maxScale: 4,
                            boundaryMargin: const EdgeInsets.all(24),
                            clipBehavior: Clip.none,
                            child: const Image(
                              image: AssetImage('assets/images/model.png'),
                              height: 125,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15171D),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 23,
                            color: Colors.blueGrey.shade700,
                            height: 1.45,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(_slides.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: isActive ? 34 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF2F3647)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 44),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage == _slides.length - 1 ? 'Finish' : 'Next',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({required this.title, required this.description});

  final String title;
  final String description;
}
