import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dog_syndrome/services/cloudinary_service.dart';
import 'package:dog_syndrome/services/user_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {

  String? uid = FirebaseAuth.instance.currentUser?.uid;
  UserFirestoreService userFirestoreService = UserFirestoreService();
  TextEditingController _displayNameController = TextEditingController();
  XFile? _previewImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async{
    FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/authen');
  }

  Future<void> _updateProfile() async{
    if (_displayNameController.text.trim().isEmpty && _previewImage == null) return;

    try {
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {

        if (_previewImage != null) {
          String? imageUrl = await CloudinaryService().uploadImage(_previewImage!.path);
          if (imageUrl != null) {
            await userFirestoreService.updatePhoto(user.uid, imageUrl);
          }
        }
        
        if (_displayNameController.text.trim().isNotEmpty) {
          await userFirestoreService.updateDisplayName(user.uid, _displayNameController.text.trim());
          _displayNameController.clear();
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Your profile has been updated.", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.lightGreenAccent,
        ));
      }
    } catch (e) {
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Something went wrong"),
          backgroundColor: Colors.redAccent,
        ));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
  try {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() => _isLoading = true);
      Navigator.pushReplacementNamed(context, '/authen');
      await userFirestoreService.deleteUser(user.uid);
      await user.delete();
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Your account has been deleted.", style: TextStyle(color: Colors.black),), backgroundColor: Colors.lightGreenAccent,)
      );
    }
  } on FirebaseAuthException catch (e) {
    if (e.code == 'requires-recent-login') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please sign out and try again.", style: TextStyle(color: Colors.black),), backgroundColor: Colors.yellow,)
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong.",), backgroundColor: Colors.red,)
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
  }

  Future<void> _resetPassword() async{
    String email = FirebaseAuth.instance.currentUser!.email!.trim();
    try{
      setState(() => _isLoading = true);
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password reset email has been sent.", style: TextStyle(color: Colors.black),), backgroundColor: Colors.lightGreenAccent,)
      );
    }on FirebaseAuthException catch (e) {
      String error = "Something went wrong.";

      if(e.code == 'too-many-requests'){
        error = "Please wait. Too many request.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent,)
      );
    }finally{
      setState(() => _isLoading = false);
    }
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
                      const SizedBox(height: 70,),
                      userProfile(userData['photoURL'], userData['displayName'], FirebaseAuth.instance.currentUser?.email),
                      
                    ]
                  );
              },
            ),
            if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator(color: Colors.orange)),
            ),
          ],
        )
        )
    );
  }


  Widget userProfile(String photoURL, String displayName, String? email){
    return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      color: Colors.white,
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, spreadRadius: 1)
      ],
    ),
    child: Column(
      children: [
        const SizedBox(height: 25),
        Stack(
          children: [
            CircleAvatar(
              radius: 80,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: _previewImage != null
                  ? FileImage(File(_previewImage!.path))
                  : (photoURL.isNotEmpty ? NetworkImage(photoURL) : null) as ImageProvider?,
              child: (_previewImage == null && photoURL.isEmpty)
                  ? Icon(Icons.person, size: 80, color: Colors.grey.shade400)
                  : null,
            ),
            Positioned(
              bottom: 5,
              right: 5,
              child: GestureDetector(
                onTap: _showImageSourceActionSheet,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD47E30),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 30),
        ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text("Email", style: TextStyle(fontSize: 12, color: Colors.grey)),
            subtitle: Text(email!, style: const TextStyle(fontSize: 16, color: Colors.black87)),
          ),
        const SizedBox(height: 10),
        TextField(
          controller: _displayNameController,
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: 'Display Name',
            hintText: displayName,
            prefixIcon: Icon(Icons.person)
          ),
        ),
        const SizedBox(height: 20),
        _buildActionButton(label: 'Save', color: Colors.green, onPressed: _updateProfile),
        const SizedBox(height: 30),
        _buildActionButton(label: 'Reset Password', color: Colors.black, onPressed: _resetPassword),
        const SizedBox(height: 10),
        _buildActionButton(label: 'Sign Out', color: Colors.red, onPressed: _signOut),
        const SizedBox(height: 10),
        _buildActionButton(label: 'Delete Account', color: Colors.red, onPressed: () => _showDeleteDialog(context)),
        const SizedBox(height: 20),
      ],
    ),
  );
  }

  Widget _buildActionButton({required String label, required Color color, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }

  void _showImageSourceActionSheet(){
      showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
          child: Padding(
            padding: EdgeInsets.all(5),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_outlined),
                title: Text("Pick from Gallery"),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text("Take a Photo"),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
            ],
          ),)
        )
      );
    }

  Future<void> _pickImage(ImageSource source) async{
    final ImagePicker _picker = ImagePicker(); 

    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxHeight: 800,
      maxWidth: 800);

    if(pickedFile != null){
      setState(() {
        _previewImage = pickedFile;
      });
    }
  }
  

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deleting Account?"),
        content: const Text("All your data will be lost and cannot be recover."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

}
