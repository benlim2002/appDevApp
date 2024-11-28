import 'package:flutter/material.dart';
import 'package:utmlostnfound/screens/home/report_item.dart';
import 'package:utmlostnfound/screens/home/lost_items.dart';
import 'package:utmlostnfound/appbar.dart';  // Import CustomAppBar
import 'package:marquee/marquee.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LostAndFoundScreen extends StatelessWidget {
  const LostAndFoundScreen({super.key});

  // Function to get the user's first name from Firestore
  Future<String> getUserFirstName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch the user's first name from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['name'] ?? 'User';
      } else {
        return 'User';
      }
    } else {
      return 'Guest';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use the CustomAppBar which already has the drawer functionality
      appBar: const CustomAppBar(
        title: "Home",
      ), // Drawer is provided by CustomDrawer
      body: Column(
        children: [
          // Marquee Welcome Message
          Container(
            color: const Color(0xFFF8E0D5), // Light peach/pale pink color
            height: 25,
            child: Marquee(
              text: 'Welcome to UTM Lost & Found! Keep an eye out for updates and announcements here.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Color.fromARGB(255, 100, 100, 100), // Soft pale yellow color
              ),
              scrollAxis: Axis.horizontal,
              blankSpace: 100,
              velocity: 50.0,
              startPadding: 10.0,
              pauseAfterRound: const Duration(seconds: 1),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFF9E6D5), // Soft pale peach
                    Color(0xFFD5EAE8), // Light pastel turquoise
                  ],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/home.png', // Path to the image
                            height: 250, // Adjust the height as needed
                            width: 250, // Adjust the width as needed
                          ),
                        ],
                      ),
                      //const SizedBox(height: 20),
                      const Text(
                        'Find it fast, return it faster',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40.0),
                        child: Text(
                          'Experience effortless recovery with our dedicated lost and found service.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const SizedBox(height: 20),
                      FutureBuilder<String>(
                        future: getUserFirstName(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Text(
                              'Hello!',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            );
                          } else {
                            return Text(
                              'Hello, ${snapshot.data}!',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ReportLostItemScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB2D8E1), // Soft pastel blue
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  'Found',
                                  style: TextStyle(fontSize: 18),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.check_circle_outline),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const FoundItemScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB7E2C6), // Light pastel green
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  'Lost',
                                  style: TextStyle(fontSize: 18),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.search),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 200),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
