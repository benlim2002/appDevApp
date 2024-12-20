import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmlostnfound/appbar.dart';
import 'package:utmlostnfound/screens/home/item_details.dart';
import 'package:utmlostnfound/screens/home/items_lost.dart';

class FoundItemScreen extends StatefulWidget {
  const FoundItemScreen({super.key});

  @override
  _FoundItemScreenState createState() => _FoundItemScreenState();
}

class _FoundItemScreenState extends State<FoundItemScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFaculty = 'All';
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _faculties = [
    'All',
    'Faculty of Computing',
    'Faculty of Civil Engineering',
    'Faculty of Mechanical Engineering',
    'Faculty of Electrical Engineering',
    'Faculty of Chemical and Energy Engineering',
    'Faculty of Science',
    'Faculty of Built Environment and Surveying',
    'Faculty of Management',
    'Faculty of Social Sciences and Humanities'
  ];

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
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
                // Faculty Dropdown with increased height
                DropdownButtonFormField<String>(
                  value: selectedFaculty,
                  items: _faculties.map((faculty) {
                    return DropdownMenuItem(
                      value: faculty,
                      child: Container(
                        height: 50, // Increase height for each item
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          faculty,
                          overflow: TextOverflow.ellipsis, // Prevent overflow if still too long
                        ),
                      ),
                    );
                  }).toList(),
                  decoration: const InputDecoration(labelText: "Faculty"),
                  isExpanded: true, // Make dropdown expand to fill the width
                  onChanged: (value) => selectedFaculty = value ?? 'All',
                ),
                const SizedBox(height: 10),
                // Date Range Selector
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

  bool _matchesFilters(Map<String, dynamic> item) {
    if (_selectedFaculty != 'All' && item['faculty'] != _selectedFaculty) {
      return false;
    }

    if (_startDate != null && _endDate != null) {
      final itemDate = DateTime.tryParse(item['date'] ?? '');
      if (itemDate == null || itemDate.isBefore(_startDate!) || itemDate.isAfter(_endDate!)) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Items Found",
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
                      hintText: "Search Items Found",
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
                    .where('postType', isEqualTo: 'Found')
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
                    final dateA = DateTime.tryParse(a['date'] ?? '');
                    final dateB = DateTime.tryParse(b['date'] ?? '');
                    
                    if (dateA == null || dateB == null) return 0;
                    return dateB.compareTo(dateA); // Sort in descending order
                  });

                  return ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final data = item.data() as Map<String, dynamic>;

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
                                    child: Text(
                                      data['name']?.substring(0, 1) ?? '?',
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
                                        data['name'] ?? 'Unknown User',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.brown[800],
                                        ),
                                      ),
                                      Text(
                                        calculatePostAge(data['date'] ?? ''),
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
                              Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[300],
                                ),
                                child: data['photo_url'] != null && data['photo_url'] != ''
                                    ? ClipRRect(
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
                                      )
                                    : const Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                        color: Colors.grey,
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

String calculatePostAge(String postDate) {
  try {
    final postDateTime = DateTime.parse(postDate);
    final now = DateTime.now();
    final difference = now.difference(postDateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute(s) ago';
    } else {
      return 'Just now';
    }
  } catch (e) {
    return 'Unknown time';
  }
}
