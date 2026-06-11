import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/app_user.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream of authentication status
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Get currently signed-in Firebase user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Fetch AppUser profile from Firestore
  Future<AppUser?> getAppUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Watch AppUser profile from Firestore (Stream)
  Stream<AppUser?> watchAppUser(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return AppUser.fromJson(doc.data()!);
          }
          return null;
        });
  }

  /// Sign In with Email & Password
  Future<UserCredential> signIn(String email, String password) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  /// Sign Up with Email & Password
  Future<UserCredential> signUp(String email, String password) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    // Initialize the Firestore user document
    if (credential.user != null) {
      final newUser = AppUser(
        uid: credential.user!.uid,
        email: email.trim(),
        onboarded: false,
      );
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(newUser.toJson());
    }

    return credential;
  }

  /// Sign Out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Update last active timestamp
  Future<void> updateUserActiveTimestamp(String uid) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      await docRef.update({
        'lastActiveAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (_) {
      // Ignore if update fails (offline mode etc.)
    }
  }

  /// Wipe all user data in Firestore (subcollections and parent)
  Future<void> wipeUserData(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);

    Future<void> deleteCollection(String name) async {
      final snap = await userRef.collection(name).get();
      for (var doc in snap.docs) {
        await doc.reference.delete();
      }
    }

    await deleteCollection('letters');
    await deleteCollection('moods');
    await deleteCollection('tasks');
    await deleteCollection('emergency_clicks');
    await deleteCollection('sos_completions');

    // Wipe main user profile doc
    await userRef.delete();
  }

  /// Update user record (e.g. for reset streak or updating details)
  Future<void> updateUser(AppUser user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toJson(), SetOptions(merge: true));
  }
}
