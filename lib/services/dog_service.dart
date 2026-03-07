import 'dart:math';

import 'package:dog_syndrome/services/user_firestore.dart';
import 'package:flutter/material.dart';

class DogService {

  UserFirestoreService userFirestoreService = UserFirestoreService();

  Widget getDogGIF(double todayKm, double dailyGoalKm) {
    if (todayKm >= dailyGoalKm) {
      int randomPos = Random().nextInt(4) + 1; 
      return Image.asset('assets/gif/dog/dog_idle$randomPos.gif', fit: BoxFit.contain,);
    } else {
      return Image.asset('assets/gif/dog/dog_sleep.gif', fit: BoxFit.contain,);
    }
  }

  Widget getDogWorkoutGIF() {
    return Image.asset('assets/gif/dog/dog_workout.gif', fit: BoxFit.contain);
  }

  Widget getDogPauseGIF(int gifIndex) {
    return Image.asset('assets/gif/dog/dog_pause$gifIndex.gif', fit: BoxFit.contain);
  }

}