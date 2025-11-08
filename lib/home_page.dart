import 'package:flutter/material.dart';
import 'services/auth_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffa8edea), Color(0xfffed6e3), Color(0xfff5f7fa)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.receipt_long,
                        size: 68, color: Colors.purpleAccent),
                    SizedBox(width: 16),
                    Icon(Icons.attach_money, size: 54, color: Colors.green),
                    SizedBox(width: 16),
                    Icon(Icons.auto_graph,
                        size: 54, color: Colors.orangeAccent),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome to Cash Memo Creator!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                    shadows: [
                      Shadow(
                          blurRadius: 8,
                          color: Colors.pinkAccent,
                          offset: Offset(1, 2))
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Text(
                  'A simple, professional memo template to get you started!',
                  style: TextStyle(
                    color: Colors.teal.shade900,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 38),
                ElevatedButton.icon(
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text(
                    'Sign in with Google',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 34, vertical: 15),
                    textStyle: const TextStyle(fontSize: 19),
                    backgroundColor: Colors.purpleAccent,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () async {
                    try {
                      await AuthService.signInWithGoogle();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Login failed: \$e')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.lock_outline, size: 28, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Text(
                      'Your data is fully secure and private',
                      style: TextStyle(color: Colors.blueGrey),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
