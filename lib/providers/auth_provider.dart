import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;

  // Only request 'email' — the minimum needed for Firebase Auth.
  // Explicitly pass the iOS CLIENT_ID so the plugin does NOT fall back to
  // reading GoogleService-Info.plist, which causes it to pick up a serverClientId
  // and request broad Google Cloud Platform scopes.
  final _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    // Providing clientId is required for iOS/macOS but should be omitted on Android 
    // to allow it to read from google-services.json automatically.
    clientId: (TargetPlatform.iOS == defaultTargetPlatform || 
               TargetPlatform.macOS == defaultTargetPlatform)
        ? '673059035521-7jhplak26g6ii2bno259t90tpuqm69g6.apps.googleusercontent.com'
        : null,
  );

  AuthStatus _status = AuthStatus.idle;
  String? _error;

  User? get user => _auth.currentUser;
  AuthStatus get status => _status;
  String? get error => _error;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isLoggedIn => _auth.currentUser != null;

  AuthProvider() {
    _auth.authStateChanges().listen((_) => notifyListeners());
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading();
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      _setSuccess();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('signIn error code: ${e.code} | msg: ${e.message}');
      _setError(_signInMessage(e.code, e.message));
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    _setLoading();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(credential.user!.uid)
          .set({'email': credential.user!.email});
      _setSuccess();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('signUp error code: ${e.code} | msg: ${e.message}');
      _setError(_signUpMessage(e.code, e.message));
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in dialog
        _status = AuthStatus.idle;
        notifyListeners();
        return false;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Automatically create a Firestore profile for new Google users
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(userCredential.user!.uid)
            .set({'email': userCredential.user!.email});
      }
      
      _setSuccess();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google signIn error: ${e.code} | msg: ${e.message}');
      _setError(_signInMessage(e.code, e.message));
      return false;
    } catch (e) {
      debugPrint('Google signIn raw error: $e');
      _setError('Не вдалося увійти через Google');
      return false;
    }
  }

  Future<bool> signInWithFacebook() async {
    _setLoading();
    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
        // Use native Facebook app if installed; fall back to system browser (not in-app web view)
        loginBehavior: LoginBehavior.nativeWithFallback,
      );
      if (result.status != LoginStatus.success) {
        _status = AuthStatus.idle;
        notifyListeners();
        return false;
      }
      final credential =
          FacebookAuthProvider.credential(result.accessToken!.tokenString);
          
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Automatically create a Firestore profile for new Facebook users
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(userCredential.user!.uid)
            .set({'email': userCredential.user!.email});
      }
      
      _setSuccess();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('FB signIn error: ${e.code} | msg: ${e.message}');
      // For OAuth invalid-credential, we should show a specific message or raw message
      // rather than the generic email/password message
      if (e.code == 'invalid-credential') {
        _setError('Недійсний токен авторизації. Перевірте налаштування Facebook у Firebase.');
      } else {
        _setError(_signInMessage(e.code, e.message));
      }
      return false;
    } catch (e) {
      debugPrint('FB signIn raw error: $e');
      _setError('Не вдалося увійти через Facebook');
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _status = AuthStatus.idle;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _status = AuthStatus.idle;
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
  }

  void _setSuccess() {
    _status = AuthStatus.success;
    _error = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = AuthStatus.error;
    _error = msg;
    notifyListeners();
  }

  String _signInMessage(String code, [String? raw]) => switch (code) {
        'user-not-found' ||
        'invalid-credential' =>
          'Немає акаунта з таким email або невірний пароль',
        'wrong-password' => 'Невірний пароль',
        'invalid-email' => 'Невірний формат email',
        'user-disabled' => 'Цей акаунт заблоковано',
        'too-many-requests' =>
          'Забагато спроб. Спробуйте пізніше або скиньте пароль',
        'account-exists-with-different-credential' =>
          'Акаунт з таким email вже існує. Увійдіть через Google або як ви реєструвалися раніше',
        'operation-not-allowed' =>
          'Email/Password вхід не увімкнено у Firebase Console',
        'network-request-failed' => 'Перевірте підключення до мережі',
        'channel-error' =>
          'Firebase Auth не налаштовано. Увімкніть Email/Password у Firebase Console → Authentication → Sign-in method',
        _ => raw ?? 'Помилка входу ($code)',
      };

  String _signUpMessage(String code, [String? raw]) => switch (code) {
        'email-already-in-use' =>
          'Цей email вже зареєстрований. Увійдіть або скиньте пароль',
        'invalid-email' => 'Невірний формат email',
        'weak-password' =>
          'Пароль занадто слабкий. Використайте мінімум 6 символів',
        'operation-not-allowed' =>
          'Реєстрація через email не увімкнена. Зверніться до підтримки',
        'too-many-requests' => 'Забагато спроб. Спробуйте пізніше',
        'network-request-failed' => 'Перевірте підключення до мережі',
        'channel-error' =>
          'Firebase Auth не налаштовано. Увімкніть Email/Password у Firebase Console → Authentication → Sign-in method',
        _ => raw ?? 'Помилка реєстрації ($code)',
      };
}
