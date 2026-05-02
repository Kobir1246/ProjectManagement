import 'package:flutter/material.dart';

enum AuthProvider { google, facebook, twitter }

class User {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final AuthProvider provider;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.provider,
  });
}

class AuthService extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;

  Future<bool> signInWithGoogle() async {
    return _signIn(AuthProvider.google);
  }

  Future<bool> signInWithFacebook() async {
    return _signIn(AuthProvider.facebook);
  }

  Future<bool> signInWithTwitter() async {
    return _signIn(AuthProvider.twitter);
  }

  Future<bool> _signIn(AuthProvider provider) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    _user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _getMockName(provider),
      email: _getMockEmail(provider),
      photoUrl: null,
      provider: provider,
    );

    _isLoading = false;
    notifyListeners();
    return true;
  }

  String _getMockName(AuthProvider provider) {
    switch (provider) {
      case AuthProvider.google:
        return 'Google User';
      case AuthProvider.facebook:
        return 'Facebook User';
      case AuthProvider.twitter:
        return 'X User';
    }
  }

  String _getMockEmail(AuthProvider provider) {
    switch (provider) {
      case AuthProvider.google:
        return 'user@gmail.com';
      case AuthProvider.facebook:
        return 'user@facebook.com';
      case AuthProvider.twitter:
        return 'user@x.com';
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _user = null;
    _isLoading = false;
    notifyListeners();
  }
}
