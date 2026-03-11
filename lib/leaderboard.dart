import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dog_syndrome/services/user_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

UserFirestoreService userFirestoreService = UserFirestoreService();

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class UserModel {
  final String uid;
  final String displayName;
  final String? photoURL;
  final int highestStreak;
  final int currentStreak;

  UserModel({
    required this.uid,
    required this.displayName,
    this.photoURL,
    this.highestStreak = 0,
    this.currentStreak = 0,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] ?? 'Unknown',
      photoURL: data['photoURL'],
      highestStreak: data['highestStreak'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
    );
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
      final snapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('role', isEqualTo: 'User')
          .get();
      
      List<UserModel> usersList = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      usersList.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));

      int rank = 0;
      UserModel? me;
      for (int i = 0; i < usersList.length; i++) {
        if (usersList[i].uid == currentUserId) {
          rank = i + 1; 
          me = usersList[i];
          break; 
        }
      }

      if (mounted) {
        setState(() {
          allUsers = usersList;
          myRealRank = rank;
          myData = me;
          isLoading = false;
        });
      }

    } catch (e) {
      debugPrint("Error fetching users: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD98A33),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background_fade.png',
              fit: BoxFit.cover,
            ),
          ),
          
          const Positioned(
            top: 100, left: 0, right: 0,
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
            top: 170, left: 20, right: 20, bottom: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))
                ],
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

                      if (myData != null && myRealRank > 10) ...[
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
                          child: _buildLeaderboardRow(
                            rank: myRealRank,
                            user: myData!,
                            isMe: true,
                          ),
                        ),
                      ]
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
            backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty 
                ? NetworkImage(user.photoURL!) 
                : null,
            child: (user.photoURL == null || user.photoURL!.isEmpty) 
                ? Icon(Icons.person, color: isMe ? Colors.deepPurple : const Color(0xFF8B5CF6)) 
                : null,
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
    if (rank <= 10) return '${rank}th';
    return '-';
  }
}