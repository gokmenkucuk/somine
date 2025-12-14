import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:somine_app/core/models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Get user by ID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [UserRepository] Error getting user: $e');
      rethrow;
    }
  }

  /// Create or update user from Firebase Auth
  Future<UserModel> createOrUpdateUser(User firebaseUser) async {
    try {
      final userRef = _usersCollection.doc(firebaseUser.uid);
      final existingDoc = await userRef.get();

      if (existingDoc.exists) {
        // Update existing user
        await userRef.update({
          'email': firebaseUser.email,
          'displayName': firebaseUser.displayName,
          'photoURL': firebaseUser.photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ [UserRepository] User updated: ${firebaseUser.uid}');
      } else {
        // Create new user
        final now = DateTime.now();
        final newUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email,
          displayName: firebaseUser.displayName,
          photoURL: firebaseUser.photoURL,
          createdAt: now,
          updatedAt: now,
        );
        await userRef.set(newUser.toFirestore());
        debugPrint('✅ [UserRepository] User created: ${firebaseUser.uid}');
      }

      // Return the updated user
      final updatedDoc = await userRef.get();
      return UserModel.fromFirestore(updatedDoc);
    } catch (e) {
      debugPrint('❌ [UserRepository] Error creating/updating user: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null) updates['displayName'] = displayName;
      if (photoURL != null) updates['photoURL'] = photoURL;

      await _usersCollection.doc(uid).update(updates);
      debugPrint('✅ [UserRepository] User profile updated: $uid');
    } catch (e) {
      debugPrint('❌ [UserRepository] Error updating user profile: $e');
      rethrow;
    }
  }

  /// Delete user
  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
      debugPrint('✅ [UserRepository] User deleted: $uid');
    } catch (e) {
      debugPrint('❌ [UserRepository] Error deleting user: $e');
      rethrow;
    }
  }

  /// Stream user changes
  Stream<UserModel?> streamUser(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }
}


