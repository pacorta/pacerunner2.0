import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:untitled/widgets/distance_unit_provider.dart';
import 'widgets/current_run.dart';
import 'widgets/tracking_provider.dart';
import 'widgets/distance_provider.dart';
import 'widgets/custom_pace_provider.dart';
import 'widgets/custom_distance_provider.dart';
import 'widgets/readable_pace_provider.dart';
import 'auth_wraper.dart';

import 'package:firebase_auth/firebase_auth.dart';

// import 'firebase/firebaseWidgets/running_stats.dart';

import '/widgets/pace_selection.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void _openSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(builder: (context, refConsumer, _) {
          final unit = refConsumer.watch(distanceUnitProvider);
          final unitLabel = unit == DistanceUnit.miles ? 'Miles' : 'Kilometers';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Units of Measurement',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  trailing: Text(
                    unitLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  onTap: () {
                    final notifier =
                        refConsumer.read(distanceUnitProvider.notifier);
                    notifier.state = unit == DistanceUnit.miles
                        ? DistanceUnit.kilometers
                        : DistanceUnit.miles;
                  },
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.black.withOpacity(0.1)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.grey.shade800,
                          title: const Text(
                            'Log out?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          actionsAlignment: MainAxisAlignment.center,
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Logout',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) {
                          Navigator.pop(context); // close sheet
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AuthWrapper()),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ),
                const SizedBox(height: 8),
                const SafeArea(child: SizedBox.shrink()),
              ],
            ),
          );
        });
      },
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
                      'images/pacebud-dark-text-logo.png',
                      height: 140,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Goal-focused Run
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const PaceSelectionWidget()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Goal-focused Run',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Quick Start Run
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(customPaceProvider.notifier).state = null;
                        ref.read(customDistanceProvider.notifier).state = null;
                        ref.read(readablePaceProvider.notifier).state = '';
                        ref.read(distanceProvider.notifier).state = 0.0;
                        ref.read(trackingProvider.notifier).state = true;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CurrentRun()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Quick Start',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
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
