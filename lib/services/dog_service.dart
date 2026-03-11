import 'package:flutter/material.dart';
import 'dart:math';

class DogService {
  Widget getDogGIF(bool isGoalReached, String petType) {
    int randomPos = Random().nextInt(3) + 1; 

    if (isGoalReached) {
      if(petType == 'cat') return Image.asset('assets/gif/cat/cat_sleep.gif', fit: BoxFit.contain,);
      return Image.asset('assets/gif/dog/dog_sleep.gif', fit: BoxFit.contain,);
    } else {
      if (petType == 'cat') return Image.asset('assets/gif/cat/cat_idle$randomPos.gif', fit: BoxFit.contain,);
      return Image.asset('assets/gif/dog/dog_idle$randomPos.gif', fit: BoxFit.contain,);
    }
  }

  Widget getDogWorkoutGIF(String petType) {
    if (petType == 'cat') return Image.asset('assets/gif/cat/cat_workout.gif', fit: BoxFit.contain);
    return Image.asset('assets/gif/dog/dog_workout.gif', fit: BoxFit.contain);
  }

  Widget getDogPauseGIF(int gifIndex, String petType) {
    if (petType == 'cat') return Image.asset('assets/gif/cat/cat_pause$gifIndex.gif', fit: BoxFit.contain);
    return Image.asset('assets/gif/dog/dog_pause$gifIndex.gif', fit: BoxFit.contain);
  }
}