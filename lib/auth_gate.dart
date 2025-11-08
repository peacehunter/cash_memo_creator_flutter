import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'memo_list.dart';
import 'home_page.dart';

/// A simple widget that decides which screen to show depending on the current
/// authentication state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // For non-web platforms, bypass the login screen and go directly to the memo list.
    if (!kIsWeb) {
      return const MemoListScreen();
    }

    // For web, use the authentication flow.
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          return const MemoListScreen();
        } else {
          return const HomePage(); // Show new intro home page before Google login
        }
        // Not logged in
      },
    );
  }
}
