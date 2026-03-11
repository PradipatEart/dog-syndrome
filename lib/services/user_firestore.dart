import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class UserFirestoreService {
  final CollectionReference user = FirebaseFirestore.instance.collection(
    'user',
  );

  Stream<QuerySnapshot> getAllUserStream() {
    return user
        .where('role', isEqualTo: 'User')
        .orderBy('displayName', descending: false)
        .snapshots();
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

  Future<void> addUser(
    String uid,
    String email,
    String displayName,
    String photoURL,
  ) {
    return user.doc(uid).set({
      'email': email,
      'role': 'User',
      'displayName': displayName,
      'photoURL': photoURL,
      'petName': 'My Dog',
      'currentStreak': 0,
      'highestStreak': 0,
      'dailyGoalKm': 5.0,
      'todayKm': 0.0,
      'todaySteps': 0,
      'isGoalReachedToday': false,
      'reachedGoalAt': null,
      'lastDailyReset': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'updatedAt': FieldValue.serverTimestamp(),
      'petType': 'dog',
    });
  }

  Future<void> updateDailyGoal(String uid, double newGoal) {
    return user.doc(uid).update({
      'dailyGoalKm': newGoal,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfile(
    String uid,
    String newDisplayName,
    String newPhotoURL,
  ) {
    return user.doc(uid).update({
      'displayName': newDisplayName,
      'photoURL': newPhotoURL,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateDisplayName(String uid, String newDisplayName) {
    return user.doc(uid).update({
      'displayName': newDisplayName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePhoto(String uid, String newPhotoURL) {
    return user.doc(uid).update({
      'photoURL': newPhotoURL,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePetName(String uid, String newPetName) {
    return user.doc(uid).update({
      'petName': newPetName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteUser(String uid) async {
    try {
      await user.doc(uid).delete();
    } catch (e) {
      debugPrint("Error deleting Firestore data: $e");
    }
  }

  Future<void> saveWorkoutData({
    required String uid,
    required int steps,
    required double totalDist,
    required int streak,
    required int highest,
    required bool isFirstTimeReached,
  }) async {
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    Map<String, dynamic> updateData = {
      'todayKm': totalDist,
      'todaySteps': steps,
      'currentStreak': streak,
      'highestStreak': highest,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isFirstTimeReached) {
      updateData['isGoalReachedToday'] = true;
      updateData['reachedGoalAt'] = FieldValue.serverTimestamp();
    }

    Map<String, dynamic> dailyStatData = {
      'date': todayStr,
      'distance': totalDist,
      'steps': steps,
      'isGoalReached': updateData['isGoalReachedToday'] ?? false,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    WriteBatch batch = FirebaseFirestore.instance.batch();

    DocumentReference userRef = user.doc(uid);
    batch.update(userRef, updateData);

    DocumentReference dailyStatRef = userRef
        .collection('dailyStats')
        .doc(todayStr);
    batch.set(dailyStatRef, dailyStatData, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> resetGoalAndProgress(String uid, double newGoal) {
    return user.doc(uid).update({
      'dailyGoalKm': newGoal,
      'currentStreak': 0,
      'todayKm': 0.0,
      'todaySteps': 0,
      'isGoalReachedToday': false,
      'reachedGoalAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> checkAndResetDailyData(
    String uid,
    Map<String, dynamic> userData,
  ) async {
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String lastResetStr = userData['lastDailyReset'] ?? "";

    if (lastResetStr != todayStr) {
      int currentStreak = userData['currentStreak'] ?? 0;
      double todayKm = (userData['todayKm'] ?? 0.0).toDouble();
      double goalKm = (userData['dailyGoalKm'] ?? 0.0).toDouble();

      if (todayKm < goalKm) {
        currentStreak = 0;
      }

      await user.doc(uid).update({
        'todayKm': 0.0,
        'todaySteps': 0,
        'isGoalReachedToday': false,
        'reachedGoalAt': null,
        'currentStreak': currentStreak,
        'lastDailyReset': todayStr,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> updatePetType(String uid, String newPetType) {
    return user.doc(uid).update({
      'petType': newPetType,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}