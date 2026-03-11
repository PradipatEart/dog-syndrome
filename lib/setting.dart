import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dog_syndrome/services/notification_service.dart';
import 'package:dog_syndrome/services/user_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserFirestoreService userFirestoreService = UserFirestoreService();

class SettingPage extends StatefulWidget {
  SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {

  String? uid = FirebaseAuth.instance.currentUser?.uid;
  late Stream<DocumentSnapshot> _userStream;
  bool _isNotiEnabled = true;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _userStream = userFirestoreService.getUserStream(uid!);
    _loadLocalSettings();
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNotiEnabled = prefs.getBool('noti_enabled') ?? true;
      int hour = prefs.getInt('noti_hour') ?? 8;
      int minute = prefs.getInt('noti_minute') ?? 0;
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _updateSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('noti_enabled', _isNotiEnabled);
    await prefs.setInt('noti_hour', _selectedTime.hour);
    await prefs.setInt('noti_minute', _selectedTime.minute);

    if (_isNotiEnabled) {
      await NotificationService().scheduleDailyNotification(
        hour:  _selectedTime.hour,
        minute: _selectedTime.minute,
      );
    } else {
      await NotificationService().cancelNotification(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xFFD47E30),
      body: Center(
        child: Stack(
          children: [
            Image.asset('assets/images/background_fade.png'),
            StreamBuilder<DocumentSnapshot>(
              stream: _userStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Something went wrong!");
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column();
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

                return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 70),
                    padding: const EdgeInsets.all(30),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Setting",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD47E30),
                          ),
                        ),
                        const SizedBox(height: 50),
                        _buildNotiSwitch(),
                        const Divider(height: 40),
                        _buildTimePicker(),
                        if(kDebugMode)
                          _buildDebugNotify()
                      ],
                    ),
                  );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNotiSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Notification", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
        Switch(
          value: _isNotiEnabled,
          activeColor: const Color(0xFFD47E30),
          onChanged: (value) {
            setState(() => _isNotiEnabled = value);
            _updateSettings();
          },
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return AnimatedOpacity(
      opacity: _isNotiEnabled ? 1.0 : 0.3,
      duration: const Duration(milliseconds: 200),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text("Reminder Time", style: TextStyle(fontSize: 18)),
        trailing: Text(
          _selectedTime.format(context),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD47E30)),
        ),
        onTap: _isNotiEnabled ? () async {
          final picked = await showTimePicker(context: context, initialTime: _selectedTime);
          if (picked != null) {
            setState(() => _selectedTime = picked);
            _updateSettings();
          }
        } : null,
      ),
    );
  }

  Widget _buildDebugNotify() {
    return ElevatedButton.icon(
      onPressed: () async {
        await NotificationService().showInstantNotification(
          "Time to get active!",
          "Don\'t forget to walk your pet today.",
        );
      },
      icon: const Icon(Icons.notifications_active, color: Colors.white),
      label: const Text("Test Notification", style: TextStyle(color: Colors.white, fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}