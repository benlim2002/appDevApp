import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmlostnfound/appbar.dart';
import 'package:utmlostnfound/screens/home/item_details.dart';

class FoundItemScreen extends StatefulWidget {
  const FoundItemScreen({super.key});

  @override
  _FoundItemScreenState createState() => _FoundItemScreenState();
}

class _FoundItemScreenState extends State<FoundItemScreen> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // This function is called whenever the search text is changed
  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Lost Items",
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
            // Search Field
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search Lost Items", // Change to "Lost" instead of "Found"
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
                onChanged: _onSearch, // Update search query
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('lost_items') // Use your correct collection
                    .where('status', isEqualTo: 'lost') // Filter for 'lost' status
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No lost items available."),
                    );
                  }

                  // Filter the lost items based on the search query
                  final lostItems = snapshot.data!.docs.where((item) {
                    final data = item.data() as Map<String, dynamic>;
                    final itemName = data['item']?.toLowerCase() ?? '';
                    final itemLocation = data['location']?.toLowerCase() ?? '';
                    final itemDescription = data['description']?.toLowerCase() ?? '';
                    // If any of the fields match the search query
                    return itemName.contains(_searchQuery) ||
                        itemLocation.contains(_searchQuery) ||
                        itemDescription.contains(_searchQuery);
                  }).toList();

                  return ListView.builder(
                    itemCount: lostItems.length,
                    itemBuilder: (context, index) {
                      final item = lostItems[index];
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
                                        data['date'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
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
                                  child: const Text("Contact"),
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
