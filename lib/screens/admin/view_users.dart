import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmlostnfound/screens/admin/admin_appbar.dart'; // Import AdminAppBar

class ViewUsersScreen extends StatefulWidget {
  const ViewUsersScreen({super.key});

  @override
  _ViewUsersScreenState createState() => _ViewUsersScreenState();
}

class _ViewUsersScreenState extends State<ViewUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedRole = 'Students'; // Default to 'Users'
  String _searchQuery = ''; // Default empty search query
  bool _isSearching = false; // Track whether the search bar is visible
  List<String> roles = ['Students', 'Security Personnel', 'Staff']; // Options to filter by roles
  int totalUsersCount = 0; // Variable to hold the total number of users

  String getFirestoreRole(String role) {
    switch (role) {
      case 'Students':
        return 'student'; // Map 'Users' to 'student'
      case 'Security Personnel':
        return 'security'; // Map 'Security Personnel' to 'security'
      case 'Staff':
        return 'staff'; // Map 'Staff' to 'staff'
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize totalUsersCount
    _fetchTotalUserCount();
  }

  // Fetch the total user count based on selected role
  Future<void> _fetchTotalUserCount() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: getFirestoreRole(_selectedRole))
          .get();

      setState(() {
        totalUsersCount = snapshot.docs.length;
      });
    } catch (e) {
      print("Error fetching total user count: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(
        title: "View Users", // Title for the View Users screen
        scaffoldKey: GlobalKey<ScaffoldState>(), // Pass the scaffoldKey to the AdminAppBar
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<String>(
                    value: _selectedRole,
                    icon: const Icon(Icons.arrow_drop_down),
                    elevation: 16,
                    style: const TextStyle(color: Colors.black),
                    underline: Container(
                      height: 2,
                      color: Colors.brown,
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedRole = newValue!; // Update selected role
                        totalUsersCount = 0; // Reset total count when role changes
                      });
                      _fetchTotalUserCount(); // Refetch the user count
                    },
                    items: roles.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching; // Toggle search input visibility
                      });
                    },
                  ),
                  if (_isSearching)
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Search by name",
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            border: InputBorder.none,
                            filled: false,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Display the total user count
              Text(
                'Total Users: $totalUsersCount', // Show the total count
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              // StreamBuilder to get the users with role and search filter
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('users')
                      .where('role', isEqualTo: getFirestoreRole(_selectedRole)) // Filter by role
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text("An error occurred. Please try again."),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("No users available."),
                      );
                    }

                    final users = snapshot.data!.docs
                        .where((user) {
                          final name = (user.data() as Map<String, dynamic>)['name'] ?? '';
                          return name.toLowerCase().contains(_searchQuery); // Filter by search query
                        })
                        .toList();

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index].data() as Map<String, dynamic>;
                        return _buildUserCard(user);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(user['name'] ?? 'Unknown User'),
        subtitle: Text(user['role'] ?? 'No role assigned'),
        leading: user['photo_url'] != null && user['photo_url'].isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  user['photo_url'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    );
                  },
                ),
              )
            : const Icon(Icons.person),
      ),
    );
  }
}