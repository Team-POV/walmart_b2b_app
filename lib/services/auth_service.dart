import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String ADMIN_CODE = "ADMIN2024"; // Fixed admin code

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
    String phone,
    String userType,
    {String? adminCode}
  ) async {
    try {
      // Validate admin code if signing up as admin
      if (userType == 'admin' && adminCode != ADMIN_CODE) {
        throw Exception('Invalid admin code');
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user data in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
    String userType,
    {String? adminCode}
  ) async {
    try {
      // Validate admin code if signing in as admin
      if (userType == 'admin' && adminCode != ADMIN_CODE) {
        throw Exception('Invalid admin code');
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verify user type
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData['userType'] != userType) {
          await _auth.signOut();
          throw Exception('Invalid user type');
        }
      }

      return userCredential;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUser != null) {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }
}