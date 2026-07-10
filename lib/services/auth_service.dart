import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save user data to SharedPreferences
  Future<void> _saveUserData({
    required String uid,
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
    await prefs.setString('name', name);
    await prefs.setString('email', email);
  }

  // Get user data from SharedPreferences
  Future<Map<String, String>?> getUserDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    final name = prefs.getString('name');
    final email = prefs.getString('email');
    if (uid == null || name == null || email == null) return null;
    return {'uid': uid, 'name': name, 'email': email};
  }

  // Clear user data on logout
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');
    await prefs.remove('name');
    await prefs.remove('email');
  }

  // Sign up
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String? uid = result.user?.uid;
      if (uid == null) return null;

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'createdAt': DateTime.now(),
      });

      await _saveUserData(uid: uid, name: name, email: email);

      return UserModel(
        uid: uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('Sign up error: $e');
      throw e;
    }
  }

  // Login
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String? uid = result.user?.uid;
      if (uid == null) throw Exception('Login failed: no uid');

      // Fetch user data from Firestore
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists) throw Exception('User data not found');

      final data = doc.data() as Map<String, dynamic>;
      // ✅ Use a different variable name to avoid conflict with the `email` parameter
      final userEmail = data['email'] ?? '';
      final userName = data['name'] ?? '';

      // Save to SharedPreferences
      await _saveUserData(uid: uid, name: userName, email: userEmail);
    } catch (e) {
      print('Login error: $e');
      throw e;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    await _clearUserData();
  }

  // Get user data from Firestore (for use elsewhere)
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(uid, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Get user data error: $e');
      return null;
    }
  }
}
