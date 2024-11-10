import 'package:flutter/material.dart';
import 'package:utmlostnfound/screens/home/report_item.dart';
import 'package:utmlostnfound/screens/home/found_item.dart';
import 'package:utmlostnfound/appbar.dart';
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
      appBar: const CustomAppBar(
        title: "Home",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      body: Column(
        children: [
          Container(
            color: const Color.fromARGB(255, 170, 206, 247),
            height: 25,
            child: Marquee(
              text: 'Welcome to UTM Lost & Found! Keep an eye out for updates and announcements here.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Color.fromARGB(255, 255, 249, 196),
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
                    Color(0xFFFFE6E6), // Light pink color
                    Color(0xFFDFFFD6), // Light green color
                  ],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cable, size: 40, color: Colors.brown[800]),
                          const SizedBox(width: 10),
                          Text(
                            'UTM LOST & FOUND',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
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
                              backgroundColor: Colors.redAccent,
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
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => FoundItemScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
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
                        ],
                      ),
                      Transform.translate(
                        offset: Offset(-20, 0),
                        child: Container(
                          height: 250,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 0, top: 0),
                                  child: Container(
                                    width: 125,
                                    height: 125,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          spreadRadius: 2,
                                          blurRadius: 10,
                                          offset: Offset(5, 5),
                                        ),
                                      ],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Image.asset(
                                      'assets/asset1.jpg',  
                                      fit: BoxFit.cover,   
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 60, top: 60),
                                  child: Container(
                                    width: 125,
                                    height: 125,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          spreadRadius: 2,
                                          blurRadius: 10,
                                          offset: Offset(5, 5),
                                        ),
                                      ],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Image.asset(
                                      'assets/asset2.jpg',
                                      fit: BoxFit.cover,     
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 120, top: 120),
                                  child: Container(
                                    width: 125,
                                    height: 125,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          spreadRadius: 2,
                                          blurRadius: 10,
                                          offset: Offset(5, 5),
                                        ),
                                      ],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Image.asset(
                                      'assets/asset3.jpg',  // The asset path to your image
                                      fit: BoxFit.cover,         // Adjust the height of the image
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
