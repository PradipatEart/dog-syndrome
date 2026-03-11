import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dog_syndrome/services/user_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/StreakCalendar.dart';

class StreakPage extends StatelessWidget {
  StreakPage({super.key});

  final UserFirestoreService userFirestoreService = UserFirestoreService();
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Streak'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userFirestoreService.getUserStream(uid!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong!"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); 
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final user = FirebaseAuth.instance.currentUser;

              try {
                await user?.delete();
                debugPrint("Auth Account Deleted Successfully");
              } catch (e) {
                debugPrint("Auth Deletion failed: $e");
              }

              await FirebaseAuth.instance.signOut();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Account not found. Please try again."),
                  backgroundColor: Colors.redAccent,
                ),
              );
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/authen',
                (route) => false,
              );
            });
            return const Center(child: CircularProgressIndicator());
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          List<DateTime> myStreakDates = [];
          int currentStreak = userData["currentStreak"] ?? 0;
          bool isGoalReachedToday = userData["isGoalReachedToday"] ?? false;

          if (currentStreak > 0) {
            if (isGoalReachedToday) {
              myStreakDates = generateStreakDates(
                currentStreak,
                DateTime.now(),
              );
            } else {
              myStreakDates = generateStreakDates(
                currentStreak, 
                DateTime.now().subtract(const Duration(days: 1)),
              );
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/images/streak.png', width: 100),
                    Text(
                      userData['currentStreak'].toString(),
                      style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                StreakCalendar(completedDates: myStreakDates),
                
                const SizedBox(height: 40)
              ],
            ),
          );
        },
      ),
    );
  }
}