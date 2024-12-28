import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:utmlostnfound/appbar.dart';
import 'package:intl/intl.dart';
import 'package:add_2_calendar/add_2_calendar.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  _AppointmentsScreenState createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String? userPhone;
  String? userId;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        setState(() {
          userPhone = userDoc.data()?['phone'];
          userId = userDoc.data()?['name'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Appointments",
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
        child: userPhone == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('items')
                  .where('aptMadeBy', isEqualTo: userId)
                  .where('userPhone', isEqualTo: userPhone)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No appointments found."),
                  );
                }

                final appointments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    final data = appointment.data() as Map<String, dynamic>;

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
                                      data['name'] ?? 'Unknown User',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.brown[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              data['item'] ?? 'Unknown Item',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Contact: ${data['contact'] ?? 'No phone number provided'}',
                              style: const TextStyle(color: Colors.black87),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Appointment Date: ${_formatTimestamp(data['aptDate'])}',
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                            ),
                                  if (data['aptDate'] != null && data['aptDate'] is Timestamp) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: _isAppointmentDateReached(data['aptDate']) ? Colors.green : Colors.red,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isAppointmentDateReached(data['aptDate']) ? 'Ready to Collect' : 'Not Ready',
                                        style: TextStyle(
                                          color: _isAppointmentDateReached(data['aptDate']) ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 89),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {
                                            _addToCalendar(data['aptDate']);
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0), // Padding
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10), // Rounded corners
                                            ),
                                          ),
                                          child: const Text(
                                            'Add to Calendar',
                                            style: TextStyle(
                                              fontSize: 12, // Font size
                                              fontWeight: FontWeight.bold, // Font weight
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  const SizedBox(height: 10),
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Not Ready',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      )  
    );
  }
}

bool _isAppointmentDateReached(Timestamp timestamp) {
  DateTime appointmentDate = timestamp.toDate();
  DateTime now = DateTime.now();
  return now.isAfter(appointmentDate) || now.isAtSameMomentAs(appointmentDate);
}

String _formatTimestamp(Timestamp? timestamp) {
  if (timestamp == null) {
    return 'TBD';
  }
  DateTime dateTime = timestamp.toDate();
  return DateFormat('MMMM d, yyyy, h:mm a').format(dateTime);
  
}

void _addToCalendar(Timestamp timestamp) {
  DateTime dateTime = timestamp.toDate();
  final Event event = Event(
    title: 'Appointment',
    description: 'Appointment to collect item',
    location: 'UTM',
    startDate: dateTime,
    endDate: dateTime.add(const Duration(minutes: 30)),
  );

  Add2Calendar.addEvent2Cal(event);
}