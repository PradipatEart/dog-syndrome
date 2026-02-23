import 'package:cloud_firestore/cloud_firestore.dart';

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

}