import 'package:dog_syndrome/services/user_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class AuthenPage extends StatelessWidget {
  AuthenPage({super.key});

  final UserFirestoreService userFirestoreService = UserFirestoreService();

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      providers: [EmailAuthProvider(), PhoneAuthProvider()],
      actions: [
        AuthStateChangeAction<UserCreated>((context, state) async {
          Navigator.pushReplacementNamed(context, '/home');
          final user = state.credential.user;
          if (user != null) {
            await userFirestoreService.addUser(
              user.uid,
              user.displayName ?? "New User",
              user.photoURL ?? "",
              0,
              0,
            );
          }
        }),
        AuthStateChangeAction<SignedIn>((context, state) {
          Navigator.pushReplacementNamed(context, '/home');
        })
      ],
      headerBuilder: (context, constraints, shrinkOffset) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Image.asset('assets/images/logo.png',));
      },
    );
  }
}