import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class PedometerService {
  int _initialSteps = -1;

  Future<bool> checkPermission() async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.activityRecognition.request();
        return status.isGranted;
      } else if (Platform.isIOS) {
        var status = await Permission.sensors.request();
        return status.isGranted;
      }
      return false;
    } catch (e) {
      debugPrint("Permission Error: $e");
      return false;
    }
  }

  Stream<Map<String, dynamic>> getStepStream() {
    return Pedometer.stepCountStream.map((event) {

      if (_initialSteps == -1) {
        _initialSteps = event.steps;
      }

      int currentSessionSteps = event.steps - _initialSteps;
      double distanceKm = (currentSessionSteps * 0.762) / 1000;

      return {
        'steps': currentSessionSteps,
        'distanceKm': distanceKm,
      };
    });
  }

  Stream<PedestrianStatus> getStatusStream() {
    return Pedometer.pedestrianStatusStream;
  }

  void reset() {
    _initialSteps = -1;
  }
}