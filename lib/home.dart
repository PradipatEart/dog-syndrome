import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dog_syndrome/services/dog_service.dart';
import 'package:dog_syndrome/services/user_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

UserFirestoreService userFirestoreService = UserFirestoreService();

class HomePage extends StatelessWidget {
  HomePage({super.key});

  String? uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD47E30),
      body: Center(
        child: Stack(
          children: [
            Image.asset('assets/images/background_fade.png'),
            StreamBuilder<DocumentSnapshot>(
              stream: userFirestoreService.getUserStream(uid!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Something went wrong!");
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column();
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;

                return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 70,),
                      userProfile(userData['photoURL'], userData['displayName']),
                      const SizedBox(height: 30,),
                      yourStreak(context,userData),
                      const SizedBox(height: 20,),
                      yourPet(context, userData['todayKm'], userData['dailyGoalKm']),
                      const SizedBox(height: 20,),
                    ]
                  );
              },
            )
          ],
        )
        )
    );
  }
}

Widget userProfile(String photoURL, String displayName){
  return Column(
          children: [Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 20,
              )
            ]
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
            child: photoURL.isEmpty ? Icon(Icons.person, size: 60, color: Colors.white,) : null,
          ),
        ),
        const SizedBox(height: 10,),
        Text(displayName ,
          style: TextStyle(
            color: Color(0xFFFDFBD4), 
            fontWeight: FontWeight.bold, 
            fontSize: 25,
            shadows: [
              Shadow(
                blurRadius: 20.0,
                color: Colors.black.withOpacity(0.7),
            ),
          ],)),],
        );
}

Widget yourStreak(BuildContext context, Map<String, dynamic> userData){
  return GestureDetector(
    onTap: () {
      Navigator.pushNamed(context, '/streak');
    },
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/images/streak.png', width: 100,),
          Text(userData['currentStreak'].toString(), style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.red),),
        ],
      ),
    ),
  );
}

Widget yourPet(BuildContext context, double todayKm, double dailyGoalKm){
  return GestureDetector(
    onTap: () {
      Navigator.pushReplacementNamed(context, '/yourpet');
    },
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text("Your Pet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF825E34))),
            const SizedBox(height: 30),
            SizedBox(
              height: 200,
              child: DogService().getDogGIF(todayKm, dailyGoalKm),
            ),
          ],
        )
    ),
  );
}
