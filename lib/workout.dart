import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dog_syndrome/services/dog_service.dart';
import 'package:dog_syndrome/services/pedometer_service.dart';
import 'package:dog_syndrome/services/user_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

UserFirestoreService userFirestoreService = UserFirestoreService();

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  String? uid = FirebaseAuth.instance.currentUser?.uid;

  late Stream<DocumentSnapshot> _userStream;

  final PedometerService _pedometerService = PedometerService();
  StreamSubscription? _stepSubscription;
  StreamSubscription? _statusSubscription;
  String _currentStatus = 'stopped';

  int _steps = 0;
  double _distanceFromSteps = 0.0;
  Timer? _timer;
  int _seconds = 0;
  bool _isPaused = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _userStream = userFirestoreService.getUserStream(uid!);
    _pedometerService.reset();
    _startTracking();
    _startTimer();
  }

  void _startTracking() async {
    bool hasPermission = await _pedometerService.checkPermission();
    if (hasPermission) {

      _stepSubscription = _pedometerService.getStepStream().listen((data) {
        if (!_isPaused) {
          setState(() {
            _steps = data['steps'];
            _distanceFromSteps = data['distanceKm'];
          });
        }
      });


      _statusSubscription = _pedometerService.getStatusStream().listen((event) {
        setState(() {
          _currentStatus = event.status;
        });
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    
    String h = hours.toString().padLeft(2, '0');
    String m = minutes.toString().padLeft(2, '0');
    String s = secs.toString().padLeft(2, '0');
    
    return "$h:$m:$s";
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildDogGIF() {
    if (_isPaused) {
      return DogService().getDogPauseGIF(2);
    }
    if (_currentStatus == 'stopped') {
      return DogService().getDogPauseGIF(1);
    }
    return DogService().getDogWorkoutGIF();
  }

  Future<void> _finishWorkout(Map<String, dynamic> userData) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      double todayKm = (userData['todayKm'] ?? 0.0).toDouble();
      double totalDistToSave = todayKm + _distanceFromSteps;
      int stepsToSave = _steps;

      await userFirestoreService.saveWorkoutData(
        uid!, 
        stepsToSave, 
        totalDistToSave
      );

      _pedometerService.reset();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/yourpet');
      }
    } catch (e) {
      debugPrint("Error saving workout: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to save data. Please try again."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD47E30),
      body: Center(
        child: Stack(
          children: [
            Image.asset('assets/images/background_fade.png'),
            
            StreamBuilder<DocumentSnapshot>(
              stream: _userStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Something went wrong!"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox();
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;

                double todayKm = (userData['todayKm'] ?? 0.0).toDouble();
                double goalKm = (userData['dailyGoalKm'] ?? 1.0).toDouble();

                double currentSessionDist = _isSaving ? 0.0 : _distanceFromSteps;
                double totalDist = todayKm + currentSessionDist; 
                double progress = totalDist / goalKm;

                if (progress > 1.0) progress = 1.0;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 80),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  const SizedBox(height: 40),
                                  const Text(
                                    "Workout",
                                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 30),
                                  
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Time", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                                      Text(_formatTime(_seconds), style: const TextStyle(fontSize: 25))
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Distance", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                                      Text("${totalDist.toStringAsFixed(2)} / ${userData['dailyGoalKm'] ?? 6} Km", 
                                           style: const TextStyle(fontSize: 25)),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 40,),
                                  SizedBox(
                                    height: 300,
                                    child: _buildDogGIF(),
                                  ),
                                  SizedBox(height: 10,),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 15,
                                          backgroundColor: Colors.grey[200],
                                          color: Colors.lightGreenAccent,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "${(progress * 100).toInt()}% of Daily Goal",
                                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20,),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _isPaused = !_isPaused;
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _isPaused ? Colors.green : Colors.orangeAccent, // เปลี่ยนสีตามสถานะ
                                            padding: const EdgeInsets.symmetric(vertical: 15),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                          ),
                                          child: Text(
                                            _isPaused ? "Start" : "Pause",
                                            style: const TextStyle(color: Colors.white, fontSize: 18),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _isSaving ? null : () => _finishWorkout(userData),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(vertical: 15),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                          ),
                                          child: _isSaving 
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                              )
                                            : const Text("Finish", style: TextStyle(color: Colors.white, fontSize: 18)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                          
                          Positioned(
                            top: 20,
                            left: 40,
                            child: InkWell(
                              onTap: () => Navigator.pushReplacementNamed(context, '/yourpet'),
                              child: Row(
                                children: const [
                                  Icon(Icons.arrow_back_ios, size: 20, color: Colors.grey),
                                  Text("Back", style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}