import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class AuthenPage extends StatelessWidget {
  const AuthenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      providers: [EmailAuthProvider(), PhoneAuthProvider()],
      actions: [
        AuthStateChangeAction<UserCreated>((context, state) {
          Navigator.pushReplacementNamed(context, '/home');
        }),
        AuthStateChangeAction<SignedIn>((context, state) {
          Navigator.pushReplacementNamed(context, '/home');
        })
      ],
      headerBuilder: (context, constraints, shrinkOffset) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: AspectRatio(
            aspectRatio: 1,
            ));
      },
    );
  }
}