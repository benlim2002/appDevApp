import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmlostnfound/screens/admin/admin_appbar.dart'; // Import AdminAppBar
import 'package:intl/intl.dart'; // For date formatting

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  _AppointmentScreenState createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
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
      appBar: AdminAppBar(
        title: "Appointments",
        scaffoldKey: GlobalKey<ScaffoldState>(),
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
          // Query only items with "TBD" status
          future: _firestore.collection('lost_items').where('status', isEqualTo: 'TBD').get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            // Get the list of items from the snapshot
            final items = snapshot.data?.docs ?? [];

            // If no items are found
            if (items.isEmpty) {
              return const Center(child: Text('No items with "TBD" status.'));
            }

            // Display the list of items
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final data = item.data() as Map<String, dynamic>;

                // Fetch aptMadeBy and phone number
                final aptMadeBy = data['aptMadeBy'] ?? 'Unknown Appointment Maker';
                final phoneNumber = data['userPhone'] ?? 'None'; // Access the phone field

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(aptMadeBy), // Use aptMadeBy for the title
                    subtitle: Text('Phone: $phoneNumber\n${data['description'] ?? 'No description'}'), // Show phone number and description
                    trailing: IconButton(
                      icon: const Icon(Icons.check_circle),
                      onPressed: () {
                        // Show the dialog to confirm the appointment
                        _showConfirmAppointmentDialog(context, item);
                      },
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
              // Button to open date picker
              ElevatedButton(
                onPressed: () => _selectDate(context),
                child: Text(_selectedDate == null
                    ? 'Pick Date'
                    : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
              ),
              const SizedBox(height: 10),
              const Text('Set appointment time:'),
              const SizedBox(height: 10),
              // Button to open time picker
              ElevatedButton(
                onPressed: () => _selectTime(context),
                child: Text(_selectedTime == null
                    ? 'Pick Time'
                    : _selectedTime!.format(context)),
              ),
              const SizedBox(height: 20),
              // Confirm button
              ElevatedButton(
                onPressed: () {
                  if (_selectedDate != null && _selectedTime != null) {
                    // Combine date and time to set the full appointment
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
                      'status': 'approved', // Change the status to "approved"
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
                    // Show error if no date or time is selected
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