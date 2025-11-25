import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../services/firebase_auth_service.dart';

class AuthModel extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userEmail;
  String? _userName;
  String? _errorMessage;
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get errorMessage => _errorMessage;

  AuthModel() {
    _initializeAuth();
  }

  // Initialize authentication state
  Future<void> _initializeAuth() async {
    // Listen to Firebase auth state changes
    _firebaseAuthService.authStateChanges.listen((User? user) {
      print('Auth state changed: ${user != null ? 'User logged in' : 'User logged out'}');
      if (user != null) {
        _isAuthenticated = true;
        _userEmail = user.email;
        _userName = user.displayName;
        _errorMessage = null;
        print('User authenticated: ${user.email}');
      } else {
        _isAuthenticated = false;
        _userEmail = null;
        _userName = null;
        print('User not authenticated');
      }
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    try {
      print('AuthModel: Starting login for $email');
      _errorMessage = null;
      final userCredential = await _firebaseAuthService.signInWithEmailAndPassword(email, password);
      if (userCredential != null) {
        print('AuthModel: Login successful for $email');
        return true;
      }
      print('AuthModel: Login failed - no user credential');
      return false;
    } catch (e) {
      print('AuthModel: Login error - $e');
      // Check if the error is a type casting issue that doesn't affect authentication
      if (e.toString().contains('PigeonUserDetails') || e.toString().contains('type cast')) {
        print('AuthModel: Type casting error detected, checking authentication status');
        // Wait a moment for auth state to update
        await Future.delayed(const Duration(milliseconds: 200));
        // Check if user is actually authenticated despite the error
        if (_firebaseAuthService.currentUser != null) {
          print('AuthModel: User is authenticated despite type casting error');
          return true;
        }
      }
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    try {
      print('Starting signup for: $email');
      _errorMessage = null;
      final userCredential = await _firebaseAuthService.createUserWithEmailAndPassword(email, password);
      if (userCredential != null) {
        print('User created successfully, updating profile');
        // Update the user's display name
        await _firebaseAuthService.updateUserProfile(displayName: name);
        print('Profile updated successfully');
        return true;
      }
      print('User creation failed');
      return false;
    } catch (e) {
      print('Signup error: $e');
      // Check if it's a type casting error but user is actually authenticated
      if (e.toString().contains('PigeonUserDetails') || e.toString().contains('type cast')) {
        print('AuthModel: Type casting error detected during signup, checking authentication status');
        await Future.delayed(const Duration(milliseconds: 200));
        if (_firebaseAuthService.currentUser != null) {
          print('AuthModel: User is authenticated despite type casting error during signup');
          return true;
        }
      }
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseAuthService.signOut();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _errorMessage = null;
      await _firebaseAuthService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

