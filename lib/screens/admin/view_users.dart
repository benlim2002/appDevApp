import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  void _showUserDetails(BuildContext context, Map<String, dynamic> user, String userId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    if (user['profileImage'] != null && user['profileImage'].isNotEmpty)
                      Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.0), // Adjust the radius as needed
                        child: Image.network(
                          user['profileImage'],
                          height: 400,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      user['name'] ?? 'Unknown Name',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contact: ${user['phone'] ?? ''}',
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'E-mail: ${user['email'] ?? ''}',
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Role: ${user['role'] ?? ''}',
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    if (user['role'] == 'student') ...[
                      Text(
                        'Faculty: ${user['faculty'] ?? ''}',
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                    ] else if (user['role'] == 'staff') ...[
                      Text(
                        'Faculty: ${user['faculty'] ?? ''}',
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                    ] else if (user['role'] == 'security') ...[
                      Text(
                        'Work Area: ${user['workarea'] ?? ''}',
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                    ],
                    ElevatedButton(
                      onPressed: () {
                        _showDeleteConfirmationDialog(context, user['name'], userId);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.red,
                      ),
                      child: const Text('Delete User'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

void _showDeleteConfirmationDialog(BuildContext context, String userName, String userId) {
  final TextEditingController nameController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Delete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please type the user\'s name to confirm deletion:'),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'User Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text == userName) {
                _deleteUser(userId);
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User name does not match')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}

void _deleteUser(String userId) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(userId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User deleted successfully')),
    );
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error deleting user: $error')),
    );
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
                      .orderBy('name') // Order by name
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

                    // Sort the filtered users alphabetically
                    users.sort((a, b) {
                      final nameA = (a.data() as Map<String, dynamic>)['name'] ?? '';
                      final nameB = (b.data() as Map<String, dynamic>)['name'] ?? '';
                      return nameA.compareTo(nameB);
                    });

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index].data() as Map<String, dynamic>;
                        return _buildUserCard(user, users[index].id);
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

  Widget _buildUserCard(Map<String, dynamic> user, String userId) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onLongPress: (){
          _showUserDetails(context, user, userId);
        },
        title: Text(user['name'] ?? 'Unknown User'),
        subtitle: Text(user['role'] ?? 'No role assigned'),
        leading: user['profileImage'] != null && user['profileImage'].isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: user['profileImage'],
                  width: 50,  // Set the width limit for the image
                  height: 50, // Set the height limit for the image
                  fit: BoxFit.cover,  // Ensure image maintains aspect ratio
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),  // Placeholder while image is loading
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.grey,
                  ),  // Error widget if the image fails to load
                ),
              )
            : const Icon(Icons.person),
      ),
    );
  }
}