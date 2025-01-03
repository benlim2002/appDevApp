// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmlostnfound/screens/security/security_appbar.dart'; // Import SecurityAppBar
import 'package:intl/intl.dart'; // For date formatting

class SecurityAppointmentScreen extends StatefulWidget {
  const SecurityAppointmentScreen({super.key});

  @override
  _SecurityAppointmentScreenState createState() => _SecurityAppointmentScreenState();
}

class _SecurityAppointmentScreenState extends State<SecurityAppointmentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // DateTime for selected date
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Function to open date picker dialog
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Function to open time picker dialog
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SecurityAppBar(
        title: "Appointments",
        scaffoldKey: GlobalKey<ScaffoldState>(), // If needed
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF9E6D5), // Soft pale peach
              Color(0xFFD5EAE8), // Light blue-gray
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder<QuerySnapshot>(
          future: _firestore.collection('items').where('postType', isEqualTo: 'TBD').get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final items = snapshot.data?.docs ?? [];

            if (items.isEmpty) {
              return const Center(child: Text('No items with "TBD" status.'));
            }

            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final data = item.data() as Map<String, dynamic>;

                // Fetch aptMadeBy and phone number
                final aptMadeBy = data['aptMadeBy'] ?? 'Unknown Appointment Maker';
                final phoneNumber = data['userPhone'] ?? 'None'; // Access the phone field

                return Card(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Retriever: $aptMadeBy',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.brown,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Phone: $phoneNumber',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        data['item'] ?? 'No description',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Show the dialog to confirm the appointment
                            _showConfirmAppointmentDialog(context, item);
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Confirm Appointment'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
              },
            );
          },
        ),
      ),
    );
  }

  // Function to show the confirmation dialog for setting appointment date and time
  void _showConfirmAppointmentDialog(BuildContext context, QueryDocumentSnapshot item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Appointment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Set appointment date:'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _selectDate(context),
                child: Text(_selectedDate == null
                    ? 'Pick Date'
                    : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
              ),
              const SizedBox(height: 10),
              const Text('Set appointment time:'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _selectTime(context),
                child: Text(_selectedTime == null
                    ? 'Pick Time'
                    : _selectedTime!.format(context)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_selectedDate != null && _selectedTime != null) {
                    final DateTime appointmentDateTime = DateTime(
                      _selectedDate!.year,
                      _selectedDate!.month,
                      _selectedDate!.day,
                      _selectedTime!.hour,
                      _selectedTime!.minute,
                    );

                    // Update the Firestore document with the appointment date and time, and status to approved
                    item.reference.update({
                      'aptDate': appointmentDateTime,
                      'postType': 'approved', // Change the status to "approved"
                    }).then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Appointment confirmed successfully')),
                      );
                      Navigator.of(context).pop(); // Close the dialog
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $error')),
                      );
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select both a date and time')),
                    );
                  }
                },
                child: const Text('Confirm Appointment'),
              ),
            ],
          ),
        );
      },
    );
  }
}
