// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Correct Firestore import
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase Authentication
import 'package:utmlostnfound/appbar.dart'; // Import your custom app bar

class ItemDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  // ignore: library_private_types_in_public_api
  _ItemDetailsScreenState createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  late Map<String, dynamic> item;
  late String userName;
  late String userPhone;
  String? profileImageUrl;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool isGuest = true; // Assume the user is a guest for this example

  @override
  void initState() {
    super.initState();
    item = widget.item; // Initialize the item state
    _checkIfUserIsGuest();
    _loadProfileImage();
  }

  Future<void> _checkIfUserIsGuest() async {
    final userFirstName = await getUserFirstName();
    setState(() {
      isGuest = userFirstName == 'Guest';
    });
  }

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

  Future<void> _loadProfileImage() async {
    String? imageUrl = await _fetchProfileImage(item['contact']);
    setState(() {
      profileImageUrl = imageUrl;
    });
  }

  Future<String?> _fetchProfileImage(String contactNumber) async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: contactNumber)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        return userSnapshot.docs.first['profileImage'];
      }
    } catch (error) {
      print('Error fetching profile image: $error');
    }
    return null;
  }

  String _formatTimestamp(String timestampString) {
    try {
      // Convert the string to an integer
      final int timestamp = int.parse(timestampString);

      // Convert Unix timestamp (milliseconds) to a DateTime object
      final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

      // Format the DateTime to a readable time format (e.g., 03:45 PM)
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      // If an error occurs, return an empty string or error message
      return '';
    }
  }

  void _launchDialer(String phoneNumber) async {
    final PermissionStatus status = await Permission.phone.request();

    if (status.isGranted) {
      final Uri url = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch $url';
      }
    } else {
      throw 'Phone permission not granted';
    }
  }

  // Function to show confirmation dialog and update the status if confirmed
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Appointment"),
          content: isGuest
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                )
              : const Text('Do you want to confirm the appointment?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (isGuest) {
                  if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter your name and phone number')),
                    );
                    return;
                  }
                  // Save the guest's name and phone number
                  userName = _nameController.text;
                  userPhone = _phoneController.text;
                  print('Guest Name: $userName');
                  print('Guest Phone: $userPhone');
                }

                Navigator.of(context).pop();
                await _updateStatusToTBD();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  // Function to directly update Firestore document status to "TBD" and store appointment maker info
  Future<void> _updateStatusToTBD() async {
    try {
      // Ensure the document reference exists
      DocumentReference itemRef = FirebaseFirestore.instance.collection('items').doc(item['id']);

      // Get the document snapshot
      DocumentSnapshot docSnapshot = await itemRef.get();

      // Check if the document exists
      if (!docSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item not found in Firestore.")),
        );
        return; // Exit if the document does not exist
      }

      String aptMadeBy = "Guest";
      if (FirebaseAuth.instance.currentUser != null) {
        // User is authenticated, fetch their details
        final user = FirebaseAuth.instance.currentUser!;
        final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userSnapshot.exists) {
          final userData = userSnapshot.data() as Map<String, dynamic>;
          userName = userData['name'] ?? 'Unknown User';
          userPhone = userData['phone'] ?? 'Unknown Phone';
          aptMadeBy = userName;
        }
      }

      await itemRef.update({
        'postType': 'TBD',
        'aptMadeBy': aptMadeBy,
        'userPhone': aptMadeBy == "Guest" ? null : userPhone,
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Appointment Recorded"),
            content: const Text("Please wait for appointment date confirmation."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Handle any errors that occur during the update
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating the status: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Item Details", // App bar title
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFE6E6), // Light pink
              Color(0xFFFFE6E6), // Light pink
              Color(0xFFFFE6E6), // Light pink
              Color(0xFFFFE6E6), // Light pink
              Color(0xFFDFFFD6), // Light green
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // White Rounded Box with Embedded Image
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Embedded Image
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: item['photo_url'] != null
                            ? Image.network(
                                item['photo_url'],
                                height: 375, // Increased height
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'assets/placeholder.png',
                                height: 375, // Increased height
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),

                      // Content inside the white box
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Show a message if the item is verified
                            if (item['verification'] == 'yes') ...[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 27),
                                    Text(
                                      "This item is ready for retrieval.",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                            ] else
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 245, 232, 232),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color.fromARGB(255, 196, 80, 80)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.unarchive,
                                      color: Color.fromARGB(255, 202, 71, 71),
                                    ),
                                    SizedBox(width: 27),
                                    Text(
                                      "Not received by UTM Security yet.",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color.fromARGB(255, 238, 154, 148),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 10),

                            // Item Title
                            Text(
                              item['item'] ?? 'Unknown Item',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Location
                            Text(
                              "Location: ${item['location'] ?? 'No location provided'}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Description
                            Text(
                              item['description'] ?? 'No description provided',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Found By Section with Contact Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.brown[200],
                                      backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
                                      child: profileImageUrl == null
                                          ? Text(
                                              item['name']?.substring(0, 1) ?? '?',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${item['name'] ?? 'Unknown User'}",
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        Text(
                                          "${item['date'] ?? ''} ${item['timestamp'] != null ? 'at ' + _formatTimestamp(item['timestamp']) : ''}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final phoneNumber = item['contact'] ?? '';

                                    if (phoneNumber.isNotEmpty) {
                                      try {
                                        // Use the _launchDialer function
                                        _launchDialer(phoneNumber);
                                      } catch (e) {
                                        // Handle exceptions and show a SnackBar
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to launch dialer: $e')),
                                        );
                                      }
                                    } else {
                                      // Handle case if no phone number is available
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("No phone number available")),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 123, 125, 230),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text("Contact"),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Polis Bantuan Retrieval Button
                            if (item['verification'] == 'yes') ...[
                              Center(
                                child: ElevatedButton(
                                  onPressed: _showConfirmationDialog, // Show confirmation dialog
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4CAF50), // Light green
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                      horizontal: 50,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    "Polis Bantuan (Retrieval)",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}