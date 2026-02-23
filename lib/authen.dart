import 'dart:io';

import 'package:dog_syndrome/services/cloudinary_service.dart';
import 'package:dog_syndrome/services/user_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AuthenPage extends StatefulWidget {
  const AuthenPage({super.key});

  @override
  State<AuthenPage> createState() => _AuthenPageState();
}

class _AuthenPageState extends State<AuthenPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final UserFirestoreService userFirestoreService = UserFirestoreService();

  bool _isLoading = false;
  bool _isObscure = true;
  int pageIndex = 0; 
  XFile? _profileImage;
  // 0 = SignIn (Login)
  // 1 = SignUp (Register)
  // 2 = Forget Password
  // 3 = Setup Profile

  void _changePage(int index) {
    setState(() {
      pageIndex = index;
    });
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
  }

  Widget showPage(int pageIndex){
    switch (pageIndex){
      case 0 : return signInPage();
      case 1 : return signUpPage();
      case 2 : return forgotPasswordPage();
      case 3 : return setupProfile();
      default: return signInPage();
    }
  }

  Future<void> _signUp() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if(email.isEmpty || password.isEmpty || confirmPassword.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please input email and password."), backgroundColor: Colors.red,)
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password must be more than 6 characters."), backgroundColor: Colors.red,)
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password mismatch."), backgroundColor: Colors.redAccent,)
      );
      return;
    }
  
    try{
      setState(() => _isLoading = true);
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email, password: password);
      
      if(userCredential.user != null){
        await userFirestoreService.addUser(
          userCredential.user!.uid,
          userCredential.user!.uid, "", 0, 0);
        
        _changePage(3);
      }
    }on FirebaseAuthException catch (e) {
      String error = "Something went wrong.";

      if (e.code == 'email-already-in-use') {
        error = "This email already taken.";
      } else if (e.code == 'weak-password') {
        error = "Password is too weak.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.redAccent,
      ));
    }finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if(email.isEmpty || password.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please input email and password."), backgroundColor: Colors.redAccent,)
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, password: password);
      
      if(userCredential.user != null){
        if(!mounted) return;
        setState(() => _isLoading = false);
        final doc = await userFirestoreService.getUserData(userCredential.user!.uid);
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String displayName = data['displayName'] ?? "";
          if (displayName == userCredential.user!.uid) {
            _changePage(3); 
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }else{
          await userFirestoreService.addUser(
          userCredential.user!.uid,
          userCredential.user!.uid, "", 0, 0);
          _changePage(3);
        }
      }
    } on FirebaseAuthException catch (e) {
      String error = "Something went wrong.";

      if (e.code == 'user-not-found') {
        error = "User not found.";
      } else if (e.code == 'wrong-password') {
        error = "Wrong Password.";
      } else if (e.code == 'invalid-email') {
        error = "Invalid email adress.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.redAccent,
      ),
    );
    }finally{
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async{
    String newDisplayName = _displayNameController.text.trim();

    if (newDisplayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You must enter your display name"),
          backgroundColor: Colors.redAccent,
        ));
        return;
    }

    try {
      setState(() => _isLoading = true);

      String? imageUrl;
      if (_profileImage != null) {
        imageUrl = await CloudinaryService().uploadImage(_profileImage!.path);
      }
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await userFirestoreService.updateProfile(user.uid, newDisplayName, imageUrl ?? "");
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
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

  Future<void> _forgetPassword() async{
    String email = _emailController.text.trim();
    if(email.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please input email."), backgroundColor: Colors.redAccent,)
      );
      return;
    }

    try{
      setState(() => _isLoading = true);
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password reset email has been sent.", style: TextStyle(color: Colors.black),), backgroundColor: Colors.lightGreenAccent,)
      );
      _changePage(0);
    }on FirebaseAuthException catch (e) {
      String error = "Something went wrong.";

      if(e.code == 'user-not-found'){
        error = "User not found.";
      }else if(e.code == 'invalid-email'){
        error = "Invalid email address.";
      }else if(e.code == 'too-many-requests'){
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
      backgroundColor: const Color(0xFFFDFBD4),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
              child: showPage(pageIndex)
            ),
          ),
          if(_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Image.asset('assets/images/dog_loading.gif', width: 200,),
              ),
            )
        ],
      )
    );
  }

  Widget signInPage(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 90),
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 1,
              )
            ],
          ),
          child: Column(
              children: [
                const SizedBox(height: 15),
                Image.asset('assets/images/logo.png', height: 100),
                const SizedBox(height: 30),
                TextField(controller: _emailController, decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                )),
                const SizedBox(height: 15),
                TextField(controller: _passwordController, 
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    }, 
                    icon: Icon(_isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey,))
                )),
                const SizedBox(height: 20),
                SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: Text('Login', style: const TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
              SizedBox(height: 15,),
              TextButton(onPressed: () => _changePage(1), child: Text("Don't have account? Register")),
              TextButton(onPressed: () => _changePage(2), child: Text("Forgot Password")),
            ], 
          ),
        )
      ],
    );
  }

  Widget signUpPage(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 1,
              )
            ],
          ),
          child: Column(
              children: [
                const SizedBox(height: 15),
                Image.asset('assets/images/logo.png', height: 100),
                const SizedBox(height: 30),
                TextField(controller: _emailController, decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                )),
                const SizedBox(height: 15),
                TextField(controller: _passwordController, 
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    }, 
                    icon: Icon(_isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey,))
                )),
                const SizedBox(height: 15),
                TextField(controller: _confirmPasswordController, 
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    }, 
                    icon: Icon(_isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey,))
                )),
                const SizedBox(height: 20),
                SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  child: Text('Register', style: const TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
              SizedBox(height: 15,),
              TextButton(onPressed: () => _changePage(0), child: Text("Already have account? Login")),
            ], 
          ),
        )
      ],
    );
  }

  Widget forgotPasswordPage(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 90),
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 1,
              )
            ],
          ),
          child: Column(
              children: [
                const SizedBox(height: 15),
                Image.asset('assets/images/logo.png', height: 100),
                const SizedBox(height: 30),
                Text("Forgot Password?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                const SizedBox(height: 30),
                TextField(controller: _emailController, decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                )),
                const SizedBox(height: 15),
                SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _forgetPassword,
                  child: Text('Send Email', style: const TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
              SizedBox(height: 15,),
              TextButton(onPressed: () => _changePage(0), child: Text("Remember you password? Login")),
            ], 
          ),
        )
      ],
    );
  }

  Widget setupProfile() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 50),
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 1,
              )
            ],
          ),
          child: Column(
              children: [
                const SizedBox(height: 15),
                Text("Let's setup your profile", style: TextStyle(fontSize: 20),),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: _showImageSourceActionSheet,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _profileImage != null ? FileImage(File(_profileImage!.path)) : null,
                    child: _profileImage != null ? null : Icon(Icons.person, size: 60, color: Colors.white,),
                  ),
                ),
                Text("Tap to change", style: TextStyle(fontSize: 15),),
                const SizedBox(height: 20),
                TextField(controller: _displayNameController, decoration: InputDecoration(
                  labelText: 'Display Name',
                  prefixIcon: const Icon(Icons.edit_outlined),
                )),
                const SizedBox(height: 20),
                SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  child: Text('Confirm', style: const TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ], 
          ),
        )
      ],
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
            )
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
        _profileImage = pickedFile;
      });
    }
  }
}