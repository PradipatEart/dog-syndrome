import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dog_syndrome/services/dog_service.dart';
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

  Future<void> _editPetName(String newName) async{
    if (newName.trim().isEmpty) return;

    try {
      await userFirestoreService.updatePetName(uid!, newName.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Your pet name has been updated.", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.lightGreenAccent,
        ));
      }
    } catch (e) {
      debugPrint("Error updating pet name: $e");
    }
  }

  void _showEditPetNameDialog(String currentName){
    TextEditingController _nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Your Pet Name"),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          maxLength: 12,
          decoration: const InputDecoration(
            hintText: "Enter new name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              _editPetName(_nameController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditGoalDialog(double currentGoal) {
    double _tempGoal = currentGoal.clamp(3.0, 20.0);
    bool _isUpdating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Set New Daily Goal"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Warning: This will reset your progress and streak!",
                style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Text(
                "${_tempGoal.toStringAsFixed(1)} Km",
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.amber),
              ),
              Slider(
                value: _tempGoal,
                min: 3.0,
                max: 20.0,
                divisions: 34,
                activeColor: _isUpdating ? Colors.grey : Colors.amber,
                onChanged: _isUpdating ? null : (value) {
                  setDialogState(() {
                    _tempGoal = value;
                  });
                },
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("3 Km", style: TextStyle(color: Colors.grey)),
                  Text("20 Km", style: TextStyle(color: Colors.grey)),
                ],
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isUpdating ? null : () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: (_isUpdating || _tempGoal.toStringAsFixed(1) == currentGoal.toStringAsFixed(1)) 
                ? null
                : () async {
                    setDialogState(() => _isUpdating = true);

                    try {
                      await userFirestoreService.resetGoalAndProgress(uid!, _tempGoal);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Goal updated to ${_tempGoal.toStringAsFixed(1)} Km!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => _isUpdating = false);
                      debugPrint("Error: $e");
                    }
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(100, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isUpdating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Confirm Reset", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
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
              stream: userFirestoreService.getUserStream(uid!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Something went wrong!");
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column();
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
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

                return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(height: 80,),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    SizedBox(height: 40,),
                                    Text("Your Pet", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),),
                                    SizedBox(height: 20,),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(userData['petName'], style: TextStyle(fontSize: 20),),
                                        IconButton(onPressed: () => _showEditPetNameDialog(userData['petName']), icon: Icon(Icons.edit))
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "${userData['todayKm'].toStringAsFixed(2)} / ${userData['dailyGoalKm']} Km",
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        IconButton(
                                          onPressed: () => _showEditGoalDialog((userData['dailyGoalKm'] ?? 5.0).toDouble()),
                                          icon: const Icon(Icons.settings, size: 20, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    Text(
                                          "${userData['todaySteps'] ?? 0} Step${userData['todaySteps'] == 1 ? '' : 's'}",
                                          style: const TextStyle(fontSize: 15, color: Colors.grey),
                                        ),
                                    SizedBox(height: 80,),
                                    SizedBox(
                                      height: 250,
                                      child: DogService().getDogGIF((userData['isGoalReachedToday'] ?? false)),
                                    ),
                                    SizedBox(height: 80,),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pushReplacementNamed(context, '/workout');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.amber,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                        ),
                                        child: Text("Workout", style: const TextStyle(color: Colors.white, fontSize: 16)),
                                      ),
                                    ),
                                    SizedBox(height: 20,),
                                  ],
                                ),
                              )
                            ),
                            Positioned(
                              top: 20,
                              left: 40,
                              child: InkWell(
                                onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                                child: Row(
                                  children: const [
                                    Icon(Icons.arrow_back_ios, size: 20, color: Colors.grey),
                                    Text("Back", style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      )
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