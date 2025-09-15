import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_screen.dart';
import 'firebase/firebaseWidgets/running_stats.dart';
import 'services/location_service.dart';
import 'widgets/run_state_provider.dart';

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell>
    with WidgetsBindingObserver {
  bool _wasTrackingBeforeBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Clean up LocationService when RootShell is disposed (e.g., on logout)
    LocationService.dispose().catchError((e) {
      print('RootShell: Error disposing LocationService: $e');
    });
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _handleAppGoingToBackground();
        break;
      case AppLifecycleState.resumed:
        _handleAppComingToForeground();
        break;
      default:
        break;
    }
  }

  void _handleAppGoingToBackground() async {
    print('RootShell: App going to background');

    // Check if there's an active running session
    final runState = ref.read(runStateProvider);
    final isRunning =
        runState == RunState.running || runState == RunState.paused;

    if (!isRunning && LocationService.isInitialized) {
      // No active running session, stop location tracking to save battery
      print('RootShell: No active run, stopping location tracking');
      _wasTrackingBeforeBackground = true;
      await LocationService.stopLocationTracking();
    } else if (isRunning) {
      print('RootShell: Active run detected, keeping location tracking active');
      _wasTrackingBeforeBackground = false;
    } else {
      _wasTrackingBeforeBackground = false;
    }
  }

  void _handleAppComingToForeground() async {
    print('RootShell: App coming to foreground');

    // If we stopped tracking when going to background and we're back on home screen,
    // restart tracking for pre-warming
    if (_wasTrackingBeforeBackground && !LocationService.isInitialized) {
      print('RootShell: Restarting location tracking for pre-warming');
      LocationService.initialize(ref);
      await LocationService.startLocationTracking();
    }
    _wasTrackingBeforeBackground = false;
  }

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
          // Show HomeScreen by default
          const HomeScreen(),

          // Persistent bottom navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color.fromRGBO(140, 82, 255, 1.0),
                    Color.fromRGBO(255, 87, 87, 1.0),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            // Always go to home (pop if we're on another page)
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.home, color: Colors.white, size: 26),
                              const SizedBox(height: 2),
                              Text('Home',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            // Navigate to stats page with NO transitions
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const RunningStatsPage(),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  return child; // No transition, just show the page
                                },
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                              ),
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bar_chart,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 26),
                              const SizedBox(height: 2),
                              Text('Stats',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
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
