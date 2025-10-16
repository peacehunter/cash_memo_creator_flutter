import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Sign in with Google'),
          onPressed: () async {
            try {
              await AuthService.signInWithGoogle();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to sign in: $e')),
              );
            }
          },
        ),
      ),
    );
  }
}