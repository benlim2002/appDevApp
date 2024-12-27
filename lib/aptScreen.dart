// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import DateFormat

class AptScreen extends StatefulWidget {
  final String itemId;
  final String userRole; // For role-based logic

  const AptScreen({super.key, required this.itemId, required this.userRole});

  @override
  _AptScreenState createState() => _AptScreenState();
}

class _AptScreenState extends State<AptScreen> {
  late Map<String, dynamic> item;
  bool isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    _fetchItemData();
  }

  Future<void> _fetchItemData() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('lost_items')
          .doc(widget.itemId)
          .get();

      if (snapshot.exists) {
        setState(() {
          item = snapshot.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching item data: $e")),
      );
    }
  }

  // Function to handle status update
  Future<void> _updateStatusToFound() async {
    try {
      // Update the status to 'Found' in Firestore
      await FirebaseFirestore.instance
          .collection('lost_items')
          .doc(widget.itemId)
          .update({'status': 'Found'});

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated to "Found"!')),
      );

      // After updating the status, navigate back to the previous screen (Security Dashboard)
      Navigator.pop(context); // This will pop the current screen off the stack and return to the previous one.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating status: $e")),
      );
    }
  }

  // Function to show confirmation dialog
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Collection'),
          content: const Text('Are you sure you want to mark this item as "Found"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Close the dialog
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Update the status if confirmed
                Navigator.of(context).pop(); // Close the dialog
                _updateStatusToFound(); // Update the status and go back
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (item.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Item not found')),
      );
    }

    // Extract and format data
    Timestamp aptDateTimestamp = item['aptDate'];
    DateTime aptDate = aptDateTimestamp.toDate();
    String formattedAptDate = DateFormat('yyyy-MM-dd hh:mm:ss a').format(aptDate);

    // Extract other fields
    String aptMadeBy = item['aptMadeBy'] ?? 'Unknown';
    String contact = item['contact'] ?? 'Not provided';
    String description = item['description'] ?? 'No description available';
    String location = item['location'] ?? 'No location provided';
    String itemName = item['item'] ?? 'Unknown Item';
    String userName = item['name'] ?? 'Unknown Name';
    String status = item['status'] ?? 'Unknown status';
    String photoUrl = item['photo_url'] ?? '';
    String userPhone = item['userPhone'] ?? 'Not provided';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Appointment Details',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF9E6D5), // Soft pale peach
              Color(0xFFD5EAE8), // Soft blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView( // Use SingleChildScrollView here
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  // Image section (if URL is provided)
                  if (photoUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photoUrl,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Item Information
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Item: $itemName',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Found By: $userName',
                          style: const TextStyle(color: Colors.black),
                        ),
                        Text(
                          'Description: $description',
                          style: const TextStyle(color: Colors.black),
                        ),
                        Text(
                          'Location: $location',
                          style: const TextStyle(color: Colors.black),
                        ),
                        Text(
                          'User Phone: $userPhone',
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Appointment Information
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appointment By: $aptMadeBy',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Contact: $contact',
                          style: const TextStyle(color: Colors.black),
                        ),
                        Text(
                          'Status: $status',
                          style: const TextStyle(color: Colors.black),
                        ),
                        Text(
                          'Appointment Date: $formattedAptDate',
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 70),

                  // "Collected" Button (Centered and Rounded)
                  Center(
                    child: ElevatedButton(
                      onPressed: _showConfirmationDialog, // Show confirmation dialog on press
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text(
                        "Collected",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 70),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
