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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                                    Text("${userData['todayKm'].toStringAsFixed(2)} / ${userData['dailyGoalKm'] ?? 6} Km", 
                                           style: const TextStyle(fontSize: 20)),
                                    SizedBox(height: 80,),
                                    SizedBox(
                                      height: 300,
                                      child: DogService().getDogGIF(userData['todayKm'], userData['dailyGoalKm']),
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