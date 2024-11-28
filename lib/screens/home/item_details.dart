import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    item = widget.item; // Initialize the item state
  }

  // Function to show confirmation dialog and update the status if confirmed
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Appointment"),
          content: const Text("Are you sure you want to make an appointment for retrieval?"),
          actions: <Widget>[
            // Cancel Button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without doing anything
              },
              child: const Text("Cancel"),
            ),
            // Confirm Button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _updateStatusToTBD(); // Update status to TBD
              },
              child: const Text("Confirm"),
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
      DocumentReference itemRef = FirebaseFirestore.instance.collection('lost_items').doc(item['id']);

      // Get the document snapshot
      DocumentSnapshot docSnapshot = await itemRef.get();

      // Check if the document exists
      if (!docSnapshot.exists) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item not found in Firestore.")),
        );
        return; // Exit if the document does not exist
      }

      // Get current user details (if logged in)
      String aptMadeBy = "Guest"; // Default to guest if no user is logged in
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

      // Proceed to update the document's status to "TBD" and add who made the appointment
      await itemRef.update({
        'status': 'TBD', // Update the status field
        'aptMadeBy': aptMadeBy, // Store the user/guest name
        'userPhone': aptMadeBy == "Guest" ? null : userPhone, // Store phone number if user
      });

      // Successfully updated the status
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item status updated to TBD and appointment recorded.")),
      );
    } catch (e) {
      // Handle any errors that occur during the update
      // ignore: use_build_context_synchronously
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
                                      child: Text(
                                        item['name']?.substring(0, 1) ?? '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
                                          "${item['date'] ?? ''}",
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
                                    final contact = item['contact'] ?? 'Unknown Contact';
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Contact: $contact"),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6C63FF), // Light purple
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text(
                                    "Contact",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Polis Bantuan Retrieval Button
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
