import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'widgets/current_run.dart';
import 'widgets/tracking_provider.dart';
import 'widgets/distance_provider.dart';
import 'widgets/custom_pace_provider.dart';
import 'widgets/custom_distance_provider.dart';
import 'widgets/readable_pace_provider.dart';
import 'widgets/inline_goal_input.dart';
import 'widgets/temp_goal_providers.dart';
import 'widgets/settings_sheet.dart';
import 'services/location_service.dart';

// import 'firebase/firebaseWidgets/running_stats.dart';

// import '/widgets/pace_selection.dart'; // Keeping for future use

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Pre-warm GPS as soon as Home is shown (non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLocationPreWarming();
      _maybeShowFirstLaunchPermissionGuide();
    });
  }

  void _startLocationPreWarming() {
    try {
      // Only start location tracking if not already initialized
      // This prevents restarting when coming back from a run
      if (!LocationService.isInitialized) {
        LocationService.initialize(ref);
        // Start without prompting so guidance dialog can appear first
        LocationService.startLocationTracking(
          promptIfDenied: false,
          elevateToAlways: false,
        );
        print('HomeScreen: Started location pre-warming');
      } else {
        print(
            'HomeScreen: Location service already initialized, skipping pre-warming');
      }
    } catch (e) {
      print('HomeScreen: Error starting location pre-warming: $e');
    }
  }

  Future<void> _maybeShowFirstLaunchPermissionGuide() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'permission_guide_shown_v1';
      final shown = prefs.getBool(key) ?? false;
      if (shown) return;

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Location Permission',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'For best app performance:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF34495E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('👉', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          style:
                              TextStyle(fontSize: 15, color: Color(0xFF2C3E50)),
                          children: [
                            TextSpan(
                              text: 'Step 1: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: 'Select '),
                            TextSpan(
                              text: '"Allow While Using App"',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3498DB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('👉', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          style:
                              TextStyle(fontSize: 15, color: Color(0xFF2C3E50)),
                          children: [
                            TextSpan(
                              text: 'Step 2: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: 'Change to '),
                            TextSpan(
                              text: '"Always Allow"',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3498DB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // Show goal setup guide after permission guide
                  _showGoalSetupGuide();
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF3498DB),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            actionsPadding: const EdgeInsets.all(16),
            actionsAlignment: MainAxisAlignment.center,
          );
        },
      );

      await prefs.setBool(key, true);
    } catch (e) {
      // ignore
    }
  }

  Future<void> _showGoalSetupGuide() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Set Your Goal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose how you want to track your run:',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF34495E),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              // Option 1: Distance only
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🏃', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style:
                            TextStyle(fontSize: 15, color: Color(0xFF2C3E50)),
                        children: [
                          TextSpan(
                            text: 'Distance only: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: 'Set just the '),
                          TextSpan(
                            text: 'distance',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B59B6),
                            ),
                          ),
                          TextSpan(text: ' you want to run'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Option 2: Time only
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⏱️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style:
                            TextStyle(fontSize: 15, color: Color(0xFF2C3E50)),
                        children: [
                          TextSpan(
                            text: 'Time only: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: 'Set just the '),
                          TextSpan(
                            text: 'time',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B59B6),
                            ),
                          ),
                          TextSpan(text: ' you want to run'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Option 3: Both distance and time
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style:
                            TextStyle(fontSize: 15, color: Color(0xFF2C3E50)),
                        children: [
                          TextSpan(
                            text: 'Distance + Time: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: 'Set '),
                          TextSpan(
                            text: 'both',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B59B6),
                            ),
                          ),
                          TextSpan(text: ' for a pace challenge'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap the numbers to change them, or leave at 0 to skip that goal.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF9B59B6),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Let\'s run!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.all(16),
          actionsAlignment: MainAxisAlignment.center,
        );
      },
    );
  }

  void _openSettingsSheet() {
    SettingsSheet.show(context);
  }

  Widget _buildRunButton() {
    // Check if user has set a goal
    final hasActiveGoal = ref.watch(customDistanceProvider) != null &&
        ref.watch(customPaceProvider) != null;
    final goalText = ref.watch(readablePaceProvider);
    final hasUnconfirmedGoal = ref.watch(hasUnconfirmedGoalProvider);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Run button
          ElevatedButton(
            onPressed: () {
              // If user has unconfirmed goal, set it first
              if (hasUnconfirmedGoal) {
                setGoalFromTempSelections(ref, context);
              }
              _startRun();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.9),
              foregroundColor: (hasActiveGoal || hasUnconfirmedGoal)
                  ? const Color.fromRGBO(140, 82, 255, 1.0)
                  : Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: (hasActiveGoal || hasUnconfirmedGoal) ? 6 : 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  (hasActiveGoal || hasUnconfirmedGoal)
                      ? Icons.track_changes
                      : Icons.play_arrow,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  (hasActiveGoal || hasUnconfirmedGoal)
                      ? 'Start with goal' // Un solo texto para cualquier goal
                      : 'Quick start',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startRun() {
    // Reset distance tracking
    ref.read(distanceProvider.notifier).state = 0.0;
    ref.read(trackingProvider.notifier).state = true;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CurrentRun()),
    );
  }

  @override
  Widget build(BuildContext context) {
    //final isTracking = ref.watch(trackingProvider);

    //december 3, 2024: added this popscope to prevent the user from going back to the current run screen
    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _openSettingsSheet,
            tooltip: 'Settings',
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 24),
                  Center(
                    child: Image.asset(
                      'images/pacebud-horizontal-dark.png',
                      height: 90,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Goal Selection
                  const InlineGoalInput(),
                  const SizedBox(height: 24),
                  // Single Run Button
                  _buildRunButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
        // bottomNavigationBar is managed by RootShell
      ),
    );
  }
}
