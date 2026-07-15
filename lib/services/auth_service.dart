import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _saveUserData({
    required String uid,
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
    await prefs.setString('name', name);
    await prefs.setString('email', email);
    print('Saved to SharedPreferences: uid=$uid, name=$name, email=$email');
  }

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('uid');
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');
    await prefs.remove('name');
    await prefs.remove('email');
  }

  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('SignUp started: email=$email, name=$name');

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? firebaseUser = result.user;
      if (firebaseUser == null) {
        print('Firebase user is null');
        return null;
      }

      print('User created: uid=${firebaseUser.uid}');

      // Set display name
      await firebaseUser.updateDisplayName(name);
      await firebaseUser.reload();
      print('Display name updated');

      // ✅ SAVE TO FIRESTORE WITH ALL FIELDS
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'email': email,
        'name': name,
        'createdAt': DateTime.now(),
      });
      print('Firestore document saved with name: $name');

      // Save to SharedPreferences
      await _saveUserData(uid: firebaseUser.uid, name: name, email: email);

      return UserModel(
        uid: firebaseUser.uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('Sign up error: $e');
      throw e;
    }
  }

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

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists) {
        print('User document does not exist in Firestore');
        throw Exception('User data not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final userEmail = data['email'] ?? '';
      final userName = data['name'] ?? '';
      print('Fetched from Firestore: name=$userName, email=$userEmail');

      await _saveUserData(uid: uid, name: userName, email: userEmail);
    } catch (e) {
      print('Login error: $e');
      throw e;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _clearUserData();
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        print('getUserData: name=${data['name']}, email=${data['email']}');
        return UserModel.fromMap(uid, data);
      }
      return null;
    } catch (e) {
      print('Get user data error: $e');
      return null;
    }
  }
}
