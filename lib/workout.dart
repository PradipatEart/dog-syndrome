import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dog_syndrome/services/dog_service.dart';
import 'package:dog_syndrome/services/notification_service.dart';
import 'package:dog_syndrome/services/pedometer_service.dart';
import 'package:dog_syndrome/services/user_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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

  double? _initialTodayKm;
  int _steps = 0;
  double _distanceFromSteps = 0.0;
  Timer? _timer;
  int _seconds = 0;
  bool _isPaused = true;
  bool _isSaving = false;
  bool _hasNotifiedGoal = false;
  double _dailyGoal = 0.0;

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

            double currentTotal = (_initialTodayKm ?? 0.0) + _distanceFromSteps;
            if (_dailyGoal > 0 && currentTotal >= _dailyGoal && !_hasNotifiedGoal) {
              _hasNotifiedGoal = true;
              _sendGoalNotification();
            }
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

  void _sendGoalNotification() async {
    await NotificationService().showInstantNotification(
      "Goal Reached!",
      "Congratulations! You've completed your ${_dailyGoal.toStringAsFixed(1)} km daily walk.",
    );
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

  Widget _buildDogGIF(String currentPetType) {
    if (_isPaused) {
      return DogService().getDogPauseGIF(2, currentPetType);
    }
    if (_currentStatus == 'stopped') {
      return DogService().getDogPauseGIF(1, currentPetType);
    }
    return DogService().getDogWorkoutGIF(currentPetType);
  }

  Future<void> _finishWorkout(Map<String, dynamic> userData) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      double todayKm = (userData['todayKm'] ?? 0.0).toDouble();
      double goalKm = (userData['dailyGoalKm'] ?? 0.0).toDouble();
      int todaySteps = userData['todaySteps'] ?? 0;
      double totalDistToSave = todayKm + _distanceFromSteps;
      int stepsToSave = todaySteps + _steps;

      int currentStreak = userData['currentStreak'] ?? 0;
      int highestStreak = userData['highestStreak'] ?? 0;
  

      bool isFirstTimeReached = (todayKm < goalKm && totalDistToSave >= goalKm);
      if (isFirstTimeReached) {
        currentStreak += 1;
        if (currentStreak > highestStreak) {
          highestStreak = currentStreak;
        }
      }

      await userFirestoreService.saveWorkoutData(
        uid: uid!,
        steps: stepsToSave,
        totalDist: totalDistToSave,
        streak: currentStreak,
        highest: highestStreak,
        isFirstTimeReached: isFirstTimeReached,
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
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    final user = FirebaseAuth.instance.currentUser;
    
                    try {
                      await user?.delete();
                      debugPrint("Auth Account Deleted Successfully");
                    } catch (e) {
                      debugPrint("Auth Deletion failed: $e");
                    }

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

                String petType = userData['petType'] ?? 'dog';

                _initialTodayKm ??= (userData['todayKm'] ?? 0.0).toDouble();
                double goalKm = (userData['dailyGoalKm'] ?? 1.0).toDouble();
                _dailyGoal = goalKm;

                double totalDist = _initialTodayKm! + _distanceFromSteps; 
                double progress = totalDist / goalKm;

                if (progress > 1.0) progress = 1.0;

                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          const Text(
                            "Workout",
                            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Time", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                              Text(_formatTime(_seconds), style: const TextStyle(fontSize: 25))
                            ],
                          ),
                          Spacer(flex: 1,),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Distance", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                              Text("${totalDist.toStringAsFixed(2)} / ${userData['dailyGoalKm'] ?? 0} Km", 
                                    style: const TextStyle(fontSize: 25)),
                            ],
                          ),
                          
                          Spacer(flex: 1,),
                          Flexible(
                            flex: 15,
                            child: SizedBox(
                              height: 250,
                              child: _buildDogGIF(petType),
                            ),
                          ),
                          Spacer(flex: 1,),
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
                          Spacer(flex: 1,),
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
                                    backgroundColor: _isPaused ? Colors.green : Colors.orangeAccent,
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
                          if (kDebugMode)
                            FloatingActionButton(
                              backgroundColor: Colors.red,
                              onPressed: () {
                                setState(() {
                                  _steps += 200; 
                                  _distanceFromSteps = _steps * 0.000762;

                                  double currentTotal = (_initialTodayKm ?? 0.0) + _distanceFromSteps;
                                  if (currentTotal >= _dailyGoal && !_hasNotifiedGoal) {
                                    _hasNotifiedGoal = true;
                                    _sendGoalNotification();
                                  }
                                });
                              },
                              child: Icon(Icons.assist_walker),
                            )
                        ],
                      ),
                    ),
                    
                    Positioned(
                      top: 120,
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}