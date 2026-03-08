import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dog_syndrome/services/user_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/StreakCalendar.dart';

class StreakPage extends StatelessWidget {
  StreakPage({super.key});

  UserFirestoreService userFirestoreService = UserFirestoreService();
  String? uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
          ), 
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Streak'),
      ),
      body: Expanded(
        child: Container(
          child:  StreamBuilder<DocumentSnapshot>(
            stream: userFirestoreService.getUserStream(uid!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Something went wrong!");
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column();
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await FirebaseAuth.instance.signOut();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Account not found. Please try again."),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    Navigator.pushNamedAndRemoveUntil(context, '/authen', (route) => false);
                  });
                  return const Center(child: CircularProgressIndicator()); 
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;

                // ต้องมาแก้เพิ่ม

                List<DateTime> myStreakDates = generateStreakDates(10, DateTime.now());

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset('assets/images/streak.png', width: 100,),
                            Text(userData['currentStreak'].toString(), style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.red),),
                          ],
                        ),
                        StreakCalendar(completedDates: myStreakDates),
                        Text(printText(userData))
                      ],
                    )
                    
                  ),
                );
              }
          ),
        )
      ),
    );
  }
}

String printText(Map<String, dynamic> userData){
  String result = "";
  for (String string in userData.keys){
    result += "${string}\n";
  }
  return result;
}