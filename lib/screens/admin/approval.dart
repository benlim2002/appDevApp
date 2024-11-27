import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmlostnfound/screens/admin/admin_appbar.dart'; // Import AdminAppBar

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});

  @override
  _ApprovalScreenState createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AdminAppBar(
        title: "Approval Screen", // Title for the Approval Screen
        scaffoldKey: _scaffoldKey, // Pass the scaffoldKey to the AdminAppBar
      ),
      drawer: AdminAppBar(title: "", scaffoldKey: _scaffoldKey).buildDrawer(context), // Add the Drawer
      body: FutureBuilder<QuerySnapshot>(
        future: _firestore.collection('lost_items').where('status', isEqualTo: 'Pending').get(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Data is empty
          final items = snapshot.data?.docs ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No items pending approval.'));
          }

          // List of items to display
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final data = item.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(data['name'] ?? 'Unknown Item'),
                  subtitle: Text(data['description'] ?? 'No description'),
                  trailing: IconButton(
                    icon: const Icon(Icons.check_circle),
                    onPressed: () {
                      // Update the status to 'Approved' in Firestore
                      item.reference.update({'status': 'Approved'}).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Item approved successfully')),
                        );
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $error')),
                        );
                      });
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
