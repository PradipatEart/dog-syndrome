import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dog_syndrome/services/user_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

UserFirestoreService userFirestoreService = UserFirestoreService();

class YourPetPage extends StatefulWidget {
  YourPetPage({super.key});

  @override
  State<YourPetPage> createState() => _YourPetPageState();
}

class _YourPetPageState extends State<YourPetPage> {

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
                      IconButton(onPressed: () {
                        Navigator.pop(context);
                      }, icon: Icon(Icons.back_hand)),
                      Text('Test')
                    ]
                  );
              },
            )
          ],
        ),
      ),
    );
  }
}