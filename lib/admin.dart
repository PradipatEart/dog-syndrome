import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dog_syndrome/services/dog_service.dart';
import 'package:dog_syndrome/services/user_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

UserFirestoreService userFirestoreService = UserFirestoreService();

class AdminPage extends StatelessWidget {
  AdminPage({super.key});

  String? uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD47E30),
      body: Center(
        child: Stack(
          children: [
            Image.asset('assets/images/background_fade.png'),

            Column(
              children: [
                SizedBox(height: 80,),
                Text('User List' ,
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 40,
                    shadows: [
                      Shadow(
                        blurRadius: 20.0,
                        color: Colors.black.withOpacity(0.7),
                    ),
                  ],)
                ),
                SizedBox(height: 40,),
                //listUser(context)
              ]
            )

          ],
        )
        )
    );
  }
}

