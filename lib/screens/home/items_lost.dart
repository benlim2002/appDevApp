import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:utmlostnfound/appbar.dart';
import 'package:utmlostnfound/screens/home/item_details.dart';
import 'package:utmlostnfound/screens/home/items_found.dart';

class LostItemsScreen extends StatefulWidget {
  const LostItemsScreen({super.key});

  @override
  _ItemsLostScreenState createState() => _ItemsLostScreenState();
}

class _ItemsLostScreenState extends State<LostItemsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFaculty = 'All';
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _faculties = [
    'All',
    'Arked Meranti',
    'Arked Cengal',
    'Arked Angkasa',
    'Arked Kolej 13',
    'Arked Kolej 9 & 10',
    'Arked Bangunan Persatuan Pelajar',
    'Arked Kolej Perdana',
    'Faculty of Computing',
    'Faculty of Civil Engineering',
    'Faculty of Mechanical Engineering',
    'Faculty of Electrical Engineering',
    'Faculty of Chemical and Energy Engineering',
    'Faculty of Science',
    'Faculty of Built Environment and Surveying',
    'Faculty of Management',
    'Faculty of Social Sciences and Humanities',
    'Kolej Tun Dr. Ismail',
    'Kolej Tun Fatimah',
    'Kolej Tun Razak',
    'Kolej Perdana',
    'Kolej 9 & 10',
    'Kolej Datin Seri Endon',
    'Kolej Dato Onn Jaafar',
    'Kolej Tun Hussien Onn',
    'Kolej Tuanku Canselor',
    'Kolej Rahman Putra',
  ];

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String selectedFaculty = _selectedFaculty;
        DateTime? startDate = _startDate;
        DateTime? endDate = _endDate;

        return AlertDialog(
          title: const Text("Filter Options"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedFaculty,
                  items: _faculties.map((faculty) {
                    return DropdownMenuItem(
                      value: faculty,
                      child: Container(
                        height: 50,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          faculty,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
                  decoration: const InputDecoration(labelText: "Faculty"),
                  isExpanded: true,
                  onChanged: (value) => selectedFaculty = value ?? 'All',
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDateRange: _startDate != null && _endDate != null
                          ? DateTimeRange(
                              start: _startDate ?? DateTime.now(),
                              end: _endDate ?? DateTime.now(),
                            )
                          : null,
                    );

                    if (picked != null) {
                      setState(() {
                        startDate = picked.start;
                        endDate = picked.end;
                      });
                    }
                  },
                  child: const Text("Select Date Range"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedFaculty = selectedFaculty;
                  _startDate = startDate;
                  _endDate = endDate;
                });
                Navigator.pop(context);
              },
              child: const Text("Apply"),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _fetchProfileImage(String contactNumber) async {
    try {
      final userSnapshot = await _firestore
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

  bool _matchesFilters(Map<String, dynamic> item) {
    if (_selectedFaculty != 'All' && item['faculty'] != _selectedFaculty) {
      return false;
    }

    if (_startDate != null && _endDate != null) {
      final itemTimestamp = item['createdAt']; // Firestore Timestamp
      if (itemTimestamp == null) {
        return false;
      }

      // Convert Firestore Timestamp to DateTime
      final itemDate = itemTimestamp.toDate();

      // Check if itemDate is within the range
      if (itemDate.isBefore(_startDate!) || itemDate.isAfter(_endDate!)) {
        return false;
      }
    }

    return true;
  }

  String createdAtString = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Items Lost ↓",
        onTitleTap: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Center(
                  child: Text(
                    "Looking for?",
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // Optional for styling
                    ),
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: ListTile(
                        title: const Center(
                          child: Text(
                            "Found Items",
                            style: TextStyle(
                              fontSize: 16, // Adjust font size if needed
                              fontWeight: FontWeight.w500, // Optional for styling
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const FoundItemScreen()),
                          );
                        },
                      ),
                    ),
                    Center(
                      child: ListTile(
                        title: const Center(
                          child: Text(
                            "Lost Items",
                            style: TextStyle(
                              fontSize: 16, // Adjust font size if needed
                              fontWeight: FontWeight.w500, // Optional for styling
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LostItemsScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFF9E6D5), // Soft pale peach
              Color(0xFFD5EAE8),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Search and Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search Items Lost",
                      hintStyle: TextStyle(
                        fontStyle: FontStyle.normal,
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    onChanged: _onSearch,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.brown),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('items')
                    .where('postType', isEqualTo: 'Lost')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No items found."),
                    );
                  }

                  // Filter items
                  final filteredItems = snapshot.data!.docs.where((item) {
                    final data = item.data() as Map<String, dynamic>;
                    final itemName = data['item']?.toLowerCase() ?? '';
                    final itemLocation = data['location']?.toLowerCase() ?? '';
                    final itemDescription = data['description']?.toLowerCase() ?? '';

                    final matchesSearch = itemName.contains(_searchQuery) ||
                        itemLocation.contains(_searchQuery) ||
                        itemDescription.contains(_searchQuery);

                    return matchesSearch && _matchesFilters(data);
                  }).toList();

                  // Sort items by date in descending order (newest first)
                  filteredItems.sort((a, b) {
                    final timestampA = a['createdAt']; // Firestore Timestamp
                    final timestampB = b['createdAt']; // Firestore Timestamp

                    if (timestampA == null || timestampB == null) return 0;

                    final dateA = timestampA.toDate(); // Convert Firestore Timestamp to DateTime
                    final dateB = timestampB.toDate(); // Convert Firestore Timestamp to DateTime

                    return dateB.compareTo(dateA); // Sort in descending order
                  });

                  return ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final data = item.data() as Map<String, dynamic>;

                      return ItemCard(data: data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ItemCard extends StatefulWidget {
  final Map<String, dynamic> data;

  const ItemCard({Key? key, required this.data}) : super(key: key);

  @override
  _ItemCardState createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    String? imageUrl = await _fetchProfileImage(widget.data['contact']);
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

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and time
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.brown[200],
                  backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
                  child: profileImageUrl == null
                      ? Text(
                          data['name']?.substring(0, 1) ?? '?',
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
                      data['name'] ?? 'Unknown User',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                    Text(
                      calculatePostAge(data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toIso8601String() : ''),  // Use createdAt here
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    // Add Verified status
                    if (data['verification'] == "yes") 
                      const Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Item image placeholder or actual image
            if (data['photo_url'] != null && data['photo_url'] != '')
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  data['photo_url'],
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
                      color: Colors.grey,
                      size: 50,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            // Item details
            Text(
              data['item'] ?? 'Unknown Item',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              data['location'] ?? 'No location provided',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 5),
            Text(
              data['description'] ?? 'No description provided',
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 10),

            // Contact Button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailsScreen(
                        item: data, // Pass the selected item's data
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[400],
                  foregroundColor: Colors.white,
                ),
                child: const Text("See More"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String calculatePostAge(String timestampString) {
  if (timestampString.isEmpty) {
    return 'Unknown';  // Handle empty or invalid date string.
  }

  try {
    // Parse the timestamp string into a DateTime object.
    DateTime postDate = DateTime.parse(timestampString);
    Duration age = DateTime.now().difference(postDate);

    // Calculate the age in days, hours, or minutes based on the difference.
    if (age.inDays > 0) {
      return '${age.inDays} day(s) ago';
    } else if (age.inHours > 0) {
      return '${age.inHours} hour(s) ago';
    } else {
      return '${age.inMinutes} minute(s) ago';
    }
  } catch (e) {
    return 'Invalid date';
  }
}