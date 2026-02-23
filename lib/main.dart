import 'package:dog_syndrome/account.dart';
import 'package:dog_syndrome/authen.dart';
import 'package:dog_syndrome/home.dart';
import 'package:dog_syndrome/leaderboard.dart';
import 'package:dog_syndrome/setting.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: FirebaseAuth.instance.currentUser == null ? '/authen' : '/home',
      routes: {
        '/authen' : (context) => AuthenPage(),
        '/home' : (context) => MainNavigation(),
      },

      theme: ThemeData(
        textTheme: GoogleFonts.kanitTextTheme(),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          floatingLabelStyle: TextStyle(color: Color(0xFFD47E30)),
          labelStyle: TextStyle(color: Colors.grey),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFD47E30), width: 2.0),),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.black,
          selectionColor: Colors.orange.withOpacity(0.3),
          selectionHandleColor: Colors.orange,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD47E30),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          )
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Color(0xFF825E34)
            
          )
        ),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(), LeaderboardPage(), AccountPage(), SettingPage()
  ];

  void _onItemTapped(int index){
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD47E30),
      body: _pages[_selectedIndex],
      bottomNavigationBar: ClipRRect(
          borderRadius: BorderRadiusGeometry.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          child: BottomNavigationBar(
          backgroundColor: Color(0xFFFDFBD4),
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 0 ? Icons.home : Icons.home_outlined,), label: "Home"),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 1 ? Icons.leaderboard : Icons.leaderboard_outlined), label: "Leaderboard"),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 2 ? Icons.person : Icons.person_outline), label: "Account"),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 3 ? Icons.settings : Icons.settings_outlined), label: "Setting"),
          ],
          showUnselectedLabels: false,
          selectedItemColor: Color(0xFFD47E30),
          unselectedItemColor: Color(0xFF825E34),
          elevation: 0,
          ),
        )
    );
  }
}