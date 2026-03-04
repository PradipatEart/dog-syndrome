import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

class UserFirestoreService {

  final CollectionReference user = FirebaseFirestore.instance.collection('user');

  Stream<QuerySnapshot> getAllUserStream() {
    final userStream = user.orderBy('name', descending: true).snapshots();
    
    return userStream;
  }

  Future<DocumentSnapshot> getUserData(String uid) {
    return user.doc(uid).get();
  }

  Stream<DocumentSnapshot> getUserStream(String uid) {
    return user.doc(uid).snapshots();
  }

  Future<void> addUser(
    String uid,
    String displayName, 
    String photoURL,
    int currentStreak,
    int highestStreak){

      return user.doc(uid).set({
        'displayName' : displayName,
        'photoURL' : photoURL,
        'currentStreak' : 0,
        'highestStreak' : 0,
        'lastCheckIn' : Timestamp.now(),
        'updatedAt' : Timestamp.now()
      });
  }

  Future<void> updateProfile(String uid, String newDisplayName, String newPhotoURL) {
    return user.doc(uid).update({
      'displayName': newDisplayName,
      'photoURL' : newPhotoURL,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> updateDisplayName(String uid, String newDisplayName) {
    return user.doc(uid).update({
      'displayName': newDisplayName,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> updatePhoto(String uid, String newPhotoURL) {
    return user.doc(uid).update({
      'photoURL' : newPhotoURL,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteUser(String uid) async {
    try {
      await user.doc(uid).delete();
    } catch (e) {
      debugPrint("Error deleting Firestore data: $e");
    }
  }

}