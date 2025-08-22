import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_screen.dart';
import 'firebase/firebaseWidgets/running_stats.dart';

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  int _index = 0;
  final PageController _pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Static gradient to avoid white flashes under pages
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color.fromRGBO(255, 87, 87, 1.0),
                  Color.fromRGBO(140, 82, 255, 1.0),
                ],
              ),
            ),
          ),
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              HomeScreen(),
              RunningStatsPage(),
            ],
          ),

          // Persistent bottom navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _index == 0
                              ? null
                              : () {
                                  setState(() => _index = 0);
                                  _pageController.animateToPage(0,
                                      duration:
                                          const Duration(milliseconds: 250),
                                      curve: Curves.easeOut);
                                },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.home,
                                  color: Colors.white
                                      .withOpacity(_index == 0 ? 1.0 : 0.5),
                                  size: 24),
                              const SizedBox(height: 2),
                              Text('Home',
                                  style: TextStyle(
                                      color: Colors.white
                                          .withOpacity(_index == 0 ? 1.0 : 0.5),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: _index == 1
                              ? null
                              : () {
                                  setState(() => _index = 1);
                                  _pageController.animateToPage(1,
                                      duration:
                                          const Duration(milliseconds: 250),
                                      curve: Curves.easeOut);
                                },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bar_chart,
                                  color: Colors.white
                                      .withOpacity(_index == 1 ? 1.0 : 0.5),
                                  size: 24),
                              const SizedBox(height: 2),
                              Text('Stats',
                                  style: TextStyle(
                                      color: Colors.white
                                          .withOpacity(_index == 1 ? 1.0 : 0.5),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
