import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:utmlostnfound/screens/authenticate/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelGroupKey: "basic",
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Channel for basic notifications like item found and verified.',
        defaultColor: Color(0xFF9D50DD),
        ledColor: Colors.white,
        channelShowBadge: true, 
      ),
    ],
    channelGroups: [
      NotificationChannelGroup(channelGroupKey: "basic",
      channelGroupName: "Basic Group")
    ]
  );



  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Applying Poppins font across the app globally
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme), // Poppins font globally
        // Define AppBar theme, etc.
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueAccent,
          titleTextStyle: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold), // Poppins font for AppBar title
        ),
      ),
      home: const SplashScreen(), // Your home screen
    );
  }
}


// SplashScreen widget with a smooth transition
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay of 2 seconds before navigating to the Login screen
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo image
            Image.asset(
              'assets/logo.png', 
              width: 100,        
              height: 100,          
            ),
            const SizedBox(height: 20), 
            // Text with Poppins font applied
            Text(
              'UTM LOST & FOUND',
              style: GoogleFonts.poppins( // Applying Poppins font
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}