import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase/firebaseWidgets/login_page.dart';
//import 'firebase/firebaseWidgets/running_stats.dart';
// import 'home_screen.dart';
import 'root_shell.dart';
import 'services/run_save_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Sync pending runs on app startup (after login)
    _syncPendingRunsOnStartup();
  }

  Future<void> _syncPendingRunsOnStartup() async {
    // Wait a bit for Firebase to fully initialize
    await Future.delayed(const Duration(seconds: 2));

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final synced = await RunSaveService.syncPendingRuns();
        if (synced > 0) {
          // ignore: avoid_print
          print('AuthWrapper: Synced $synced pending runs on startup');
        }
      } catch (e) {
        // ignore: avoid_print
        print('AuthWrapper: Error syncing pending runs: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      //This stream listens for changes in the user's authentication state,
      //allowing the app to switch between the login page and the main running stats page.
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          // Use RootShell so the bottom navigation bar is persistent
          return const RootShell();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
