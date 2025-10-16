import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  const AuthService._();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Expose auth state changes so UI can react accordingly.
  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Sign in the user with Google using platform-specific flows.
  static Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      return _auth.signInWithPopup(googleProvider);
    } else {
      throw UnsupportedError('Google sign-in is only available in web builds.');
    }
    // On mobile/desktop, use the native Google sign-in flow.
  }

  /// Sign the current user out.
  static Future<void> signOut() => _auth.signOut();
}