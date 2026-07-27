import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Đăng nhập bằng Google
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      print('Lỗi đăng nhập Google: $e');
      return null;
    }
  }

  /// Đăng nhập bằng Facebook
  Future<Map<String, dynamic>?> signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );
      if (result.status == LoginStatus.success) {
        return await FacebookAuth.instance.getUserData();
      }
    } catch (e) {
      print('Lỗi đăng nhập Facebook: $e');
    }
    return null;
  }
}