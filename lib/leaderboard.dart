import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dog_syndrome/services/user_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

UserFirestoreService userFirestoreService = UserFirestoreService();

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({Key? key}) : super(key: key);

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class UserModel {
  final String uid;
  final String displayName;
  final String? photoURL;
  final DateTime? lastCheckIn;
  final int highestStreak;
  final int currentStreak;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.displayName,
    this.photoURL,
    this.lastCheckIn,
    this.highestStreak = 0,
    this.currentStreak = 0,
    this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] ?? 'Unknown',
      photoURL: data['photoURL'],
      lastCheckIn: data['lastcheckIn'] != null ? (data['lastcheckIn'] as Timestamp).toDate() : null,
      highestStreak: data['HighestStreak'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'photoURL': photoURL,
      'lastcheckIn': lastCheckIn,
      'HighestStreak': highestStreak,
      'currentStreak': currentStreak,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  
  List<UserModel> allUsers = [];
  UserModel? myData;
  int myRealRank = 99;
  bool isLoading = true; 

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
  }

  Future<void> _fetchAllUsers() async {
    try {
      
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      
      
      List<UserModel> usersList = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      
      usersList.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));

      
      int rank = 99;
      UserModel? me;
      for (int i = 0; i < usersList.length; i++) {
        if (usersList[i].uid == currentUserId) {
          rank = i + 1; 
          me = usersList[i];
          break; 
        }
      }

      
      setState(() {
        allUsers = usersList;
        myRealRank = rank;
        myData = me;
        isLoading = false;
      });

    } catch (e) {
      print("Error fetching users: $e");
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD98A33),
    
      body: Stack(
        children: [
          
          Positioned(
            top: 0, left: 0, right: 0, height: 280,
            child: Image.network(
              'https://picsum.photos/seed/park/800/400',
              fit: BoxFit.cover,
            ),
          ),
          
          
          const Positioned(
            top: 80, left: 0, right: 0,
            child: Center(
              child: Text(
                'Leaderboard',
                style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                ),
              ),
            ),
          ),

          
          Positioned(
            top: 160, left: 20, right: 20, bottom: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: isLoading 
                
                ? const Center(child: CircularProgressIndicator()) 
                : Column(
                    children: [
                      
                      Expanded(
                        child: allUsers.isEmpty 
                          ? const Center(child: Text('ยังไม่มีข้อมูลจัดอันดับ'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              
                              itemCount: allUsers.length > 10 ? 10 : allUsers.length,
                              itemBuilder: (context, index) {
                                UserModel user = allUsers[index];
                                bool isMe = user.uid == currentUserId;

                                return _buildLeaderboardRow(
                                  rank: index + 1,
                                  user: user,
                                  isMe: isMe,
                                );
                              },
                            ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(height: 1, color: Colors.grey),
                      ),

                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                        ),
                        
                        child: myData == null 
                          ? const SizedBox() 
                          : _buildLeaderboardRow(
                              rank: myRealRank,
                              user: myData!,
                              isMe: true,
                            ),
                      ),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildLeaderboardRow({required int rank, required UserModel user, bool isMe = false}) {
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Text(
              _getRankString(rank),
              style: TextStyle(
                fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
                fontSize: 16,
                color: isMe ? Colors.black : Colors.black87,
              ),
            ),
          ),
          CircleAvatar(
            backgroundColor: isMe ? const Color(0xFFD1C4E9) : const Color(0xFFEBE2FC),
            backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
            child: user.photoURL == null ? Icon(Icons.person, color: isMe ? Colors.deepPurple : const Color(0xFF8B5CF6)) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              user.displayName,
              style: TextStyle(fontSize: 16, fontWeight: isMe ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.red),
              Text(
                '${user.currentStreak}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRankString(int rank) {
    if (rank == 1) return '1st';
    if (rank == 2) return '2nd';
    if (rank == 3) return '3rd';
    if (rank > 99) return '99+';
    return '${rank}th';
  }
}