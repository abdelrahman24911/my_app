import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthModel extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userEmail;
  String? _userName;
  Map<String, UserAccount> _userAccounts = {};

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get userName => _userName;

  AuthModel() {
    _loadAuthState();
    _loadUserAccounts();
  }

  // Load authentication state from storage
  Future<void> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    _userEmail = prefs.getString('userEmail');
    _userName = prefs.getString('userName');
    notifyListeners();
  }

  // Load user accounts from storage
  Future<void> _loadUserAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString('userAccounts');
    if (accountsJson != null) {
      final Map<String, dynamic> accountsMap = json.decode(accountsJson);
      _userAccounts = accountsMap.map((key, value) => 
        MapEntry(key, UserAccount.fromJson(value)));
    }
  }

  // Save authentication state to storage
  Future<void> _saveAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', _isAuthenticated);
    await prefs.setString('userEmail', _userEmail ?? '');
    await prefs.setString('userName', _userName ?? '');
  }

  // Save user accounts to storage
  Future<void> _saveUserAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsMap = _userAccounts.map((key, value) => 
      MapEntry(key, value.toJson()));
    await prefs.setString('userAccounts', json.encode(accountsMap));
  }

  Future<bool> login(String email, String password) async {
    // Check if user exists and password matches
    if (_userAccounts.containsKey(email)) {
      final account = _userAccounts[email]!;
      if (account.password == password) {
        _isAuthenticated = true;
        _userEmail = email;
        _userName = account.name;
        await _saveAuthState();
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  Future<bool> signUp(String email, String password, String name) async {
    // Check if user already exists
    if (_userAccounts.containsKey(email)) {
      return false; // User already exists
    }

    // Create new user account
    _userAccounts[email] = UserAccount(
      email: email,
      password: password,
      name: name,
    );

    // Save accounts and authenticate
    await _saveUserAccounts();
    _isAuthenticated = true;
    _userEmail = email;
    _userName = name;
    await _saveAuthState();
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _userEmail = null;
    _userName = null;
    await _saveAuthState();
    notifyListeners();
  }

  // Clear all stored data (for testing or account deletion)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isAuthenticated = false;
    _userEmail = null;
    _userName = null;
    _userAccounts.clear();
    notifyListeners();
  }
}

class UserAccount {
  final String email;
  final String password;
  final String name;

  UserAccount({
    required this.email,
    required this.password,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'name': name,
  };

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
    email: json['email'],
    password: json['password'],
    name: json['name'],
  );
}
