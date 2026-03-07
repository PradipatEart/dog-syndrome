import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class UserFirestoreService {

  final CollectionReference user = FirebaseFirestore.instance.collection('user');

  Stream<QuerySnapshot> getAllUserStream() {
    final userStream = user.orderBy('name', descending: true).snapshots();
    
    return userStream;
  }

  Stream<DocumentSnapshot> getDailyStatsStream(String uid) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return user.doc(uid).collection('dailyStats').doc(today).snapshots();
  }

  Future<DocumentSnapshot> getUserData(String uid) {
    return user.doc(uid).get();
  }

  Stream<DocumentSnapshot> getUserStream(String uid) {
    return user.doc(uid).snapshots();
  }

  Future<void> addUser(String uid, String displayName, String photoURL) {
    return user.doc(uid).set({
      'displayName': displayName,
      'photoURL': photoURL,
      'petName': 'My Dog',
      'currentStreak': 0,
      'highestStreak': 0,
      'dailyGoalKm': 5.0,
      'todayKm': 0.0,
      'lastCheckIn': Timestamp.now(),
      'updatedAt': Timestamp.now()
    });
  }

  Future<void> updateDailyGoal(String uid, double newGoal) {
    return user.doc(uid).update({
      'dailyGoalKm': newGoal,
      'updatedAt': Timestamp.now(),
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

  Future<void> updatePetName(String uid, String newPetName) {
  return user.doc(uid).update({
    'petName': newPetName,
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

  Future<void> saveWorkoutData(String uid, int steps, double distanceKm) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await user.doc(uid).update({
      'todayKm': distanceKm,
      'updatedAt': Timestamp.now(),
    });

    await user.doc(uid).collection('dailyStats').doc(today).set({
      'steps': steps,
      'distanceKm': distanceKm,
      'date': today,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

}