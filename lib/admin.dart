import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dog_syndrome/services/user_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

UserFirestoreService userFirestoreService = UserFirestoreService();

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String? uid = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD47E30),
      body: Center(
        child: Stack(
          children: [
            Image.asset('assets/images/background_fade.png'),

            Column(
              children: [
                SizedBox(height: 80,),
                Text('User List' ,
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 40,
                    shadows: [
                      Shadow(
                        blurRadius: 20.0,
                        color: Colors.black.withOpacity(0.7),
                    ),
                  ],)
                ),
                SizedBox(height: 20,),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search user by name...",
                        prefixIcon: const Icon(Icons.search, color: Colors.orange),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () => _searchController.clear(),
                            ) 
                          : null,
                      ),
                    ),
                  ),
                ),
                listUser(context, _searchQuery)
              ]
            )

          ],
        )
        )
    );
  }
}

Widget listUser(BuildContext mainContext, String searchQuery) {
  return Expanded(
    child: StreamBuilder<QuerySnapshot>(
      stream: userFirestoreService.getAllUserStream(),
      builder: (streamContext, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading users.", style: TextStyle(color: Colors.white)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No regular users found.", style: TextStyle(color: Colors.white, fontSize: 18)));
        }

        var allUsers = snapshot.data!.docs;
        var filteredUsers = allUsers.where((doc) {
          var userData = doc.data() as Map<String, dynamic>;
          String name = (userData['displayName'] ?? '').toString().toLowerCase();
          return name.contains(searchQuery);
        }).toList();

        if (filteredUsers.isEmpty) {
          return const Center(child: Text("No matching users.", style: TextStyle(color: Colors.white, fontSize: 18)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: filteredUsers.length,
          itemBuilder: (listContext, index) {
            var userData = filteredUsers[index].data() as Map<String, dynamic>;
            String targetUid = filteredUsers[index].id;
            
            String displayName = userData['displayName'] ?? 'Unknown User';
            String photoURL = userData['photoURL'] ?? '';
            String email = userData['email'] ?? 'No Email';

            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
                  child: photoURL.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                ),
                title: Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Text(
                  email,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange, size: 30),
                  onPressed: () {
                    _showInfo(mainContext, targetUid, userData);
                  },
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

void _showInfo(BuildContext mainContext, String targetUid, Map<String, dynamic> userData) {
  String displayName = userData['displayName'] ?? 'Unknown User';
  String email = userData['email'] ?? 'No Email';
  String photoURL = userData['photoURL'] ?? '';
  int streak = userData['currentStreak'] ?? 0;
  int higheststreak = userData['highestStreak'] ?? 0;

  showDialog(
    context: mainContext,
    builder: (infoDialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("User Info", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      content: SizedBox(
        width: double.maxFinite, 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
              child: photoURL.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 60) : null,
            ),
            const SizedBox(height: 15),
            Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(email, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 15),
            
            Text("Streak", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            Text("Current: $streak\nHighest: $higheststreak", style: const TextStyle(color: Colors.black)),
            
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 15),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(infoDialogContext);
                    _showChangeNameDialog(mainContext, targetUid, displayName);
                  },
                  icon: const Icon(Icons.edit_note, color: Colors.white),
                  label: const Text("Change Name", style: TextStyle(fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                
                ElevatedButton.icon(
                  onPressed: () async {
                    if (email == 'No Email') {
                      ScaffoldMessenger.of(mainContext).showSnackBar(const SnackBar(content: Text("User has no email!")));
                      return;
                    }
                    Navigator.pop(infoDialogContext);
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                      if (mainContext.mounted) {
                        ScaffoldMessenger.of(mainContext).showSnackBar(SnackBar(content: Text("Password reset email sent to $email"), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      if (mainContext.mounted) {
                        ScaffoldMessenger.of(mainContext).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                      }
                    }
                  },
                  icon: const Icon(Icons.lock_reset, color: Colors.white),
                  label: const Text("Reset Password", style: TextStyle(fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(infoDialogContext);
                    _showDeleteConfirmDialog(mainContext, targetUid, displayName);
                  },
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                  label: const Text("Delete Account", style: TextStyle(fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(infoDialogContext),
          child: const Text("Close", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ),
      ],
    ),
  );
}

void _showChangeNameDialog(BuildContext mainContext, String targetUid, String currentName) {
  TextEditingController nameController = TextEditingController(text: currentName);

  showDialog(
    context: mainContext,
    builder: (nameDialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Change Display Name"),
      content: TextField(
        controller: nameController,
        decoration: const InputDecoration(
          labelText: "New Name",
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(nameDialogContext), 
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () async {
            String newName = nameController.text.trim();
            if (newName.isNotEmpty) {
              Navigator.pop(nameDialogContext);

              try {
                await userFirestoreService.updateDisplayName(targetUid, newName);
                
                if (mainContext.mounted) {
                  ScaffoldMessenger.of(mainContext).showSnackBar(
                    const SnackBar(
                      content: Text("Name updated successfully."), 
                      backgroundColor: Colors.green
                    ),
                  );
                }
              } catch (e) {
                if (mainContext.mounted) {
                  ScaffoldMessenger.of(mainContext).showSnackBar(
                    SnackBar(
                      content: Text("Failed to update: $e"), 
                      backgroundColor: Colors.red
                    ),
                  );
                }
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text("Save", style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

void _showDeleteConfirmDialog(BuildContext mainContext, String targetUid, String userName) {
  showDialog(
    context: mainContext,
    builder: (deleteDialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Delete User", style: TextStyle(color: Colors.red)),
      content: Text("Are you sure you want to delete '$userName'? This action cannot be undone."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(deleteDialogContext),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () async {

            Navigator.pop(deleteDialogContext);

            try {
              await userFirestoreService.deleteUser(targetUid);
              
              if(mainContext.mounted) {
                ScaffoldMessenger.of(mainContext).showSnackBar(
                  SnackBar(content: Text("User '$userName' deleted."), backgroundColor: Colors.green),
              ) ;
              }
            } catch (e) {
              if(mainContext.mounted) {
                ScaffoldMessenger.of(mainContext).showSnackBar(
                  SnackBar(content: Text("Delete failed: $e"), backgroundColor: Colors.red),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text("Delete", style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}