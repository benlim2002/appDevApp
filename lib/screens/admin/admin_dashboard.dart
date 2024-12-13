import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:utmlostnfound/screens/admin/admin_appbar.dart'; // Import AdminAppBar
import 'package:utmlostnfound/aptScreen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int totalItems = 0;
  int itemsFound = 0;
  int itemsLost = 0;
  int itemsApproved = 0;

  bool isLoading = true;
  bool isPaginating = false;
  DocumentSnapshot? lastDocument;
  List<DocumentSnapshot> allItems = [];
  List<DocumentSnapshot> filteredItems = []; // List for filtered items
  String currentFilter = 'all'; // Default to 'all'
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadDashboardMetrics();
    _loadMoreItems();  // Load the first batch of items immediately
  }

  // Load metrics like total, found, lost, and approved items
  Future<void> _loadDashboardMetrics() async {
    try {
      final totalSnapshot = await _firestore.collection('lost_items').get();
      final foundSnapshot = await _firestore
          .collection('lost_items')
          .where('status', isEqualTo: 'found')
          .get();
      final lostSnapshot = await _firestore
          .collection('lost_items')
          .where('status', isEqualTo: 'lost')
          .get();
      final approvedSnapshot = await _firestore
          .collection('lost_items')
          .where('status', isEqualTo: 'approved')
          .get();

      setState(() {
        totalItems = totalSnapshot.docs.length;
        itemsFound = foundSnapshot.docs.length;
        itemsLost = lostSnapshot.docs.length;
        itemsApproved = approvedSnapshot.docs.length;
        isLoading = false;
      });
    } catch (error) {
      print('Error loading metrics: $error');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dashboard data: $error')),
      );
    }
  }

  // Fetch paginated data based on the current filter (found, lost, all, or approved)
  Future<void> _loadMoreItems() async {
    if (isPaginating) return; // Prevent multiple calls at once

    setState(() {
      isPaginating = true;
    });

    QuerySnapshot querySnapshot;
    String filterStatus = currentFilter == 'all' ? 'all' : currentFilter;

    if (lastDocument == null) {
      if (filterStatus == 'all') {
        querySnapshot = await _firestore
            .collection('lost_items')
            .orderBy('date', descending: true)
            .limit(20)
            .get();
      } else {
        querySnapshot = await _firestore
            .collection('lost_items')
            .where('status', isEqualTo: filterStatus)
            .orderBy('date', descending: true)
            .limit(20)
            .get();
      }
    } else {
      if (filterStatus == 'all') {
        querySnapshot = await _firestore
            .collection('lost_items')
            .orderBy('date', descending: true)
            .startAfterDocument(lastDocument!)
            .limit(20)
            .get();
      } else {
        querySnapshot = await _firestore
            .collection('lost_items')
            .where('status', isEqualTo: filterStatus)
            .orderBy('date', descending: true)
            .startAfterDocument(lastDocument!)
            .limit(20)
            .get();
      }
    }

    if (querySnapshot.docs.isNotEmpty) {
      lastDocument = querySnapshot.docs.last;
      allItems.addAll(querySnapshot.docs);
      _applySearchFilter(); // Apply search filter after loading more items
    }

    setState(() {
      isPaginating = false;
    });
  }

  // Handle search query update
  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
    });
    _applySearchFilter(); // Apply the search filter to the items
  }

  // Apply the search filter to the items list
  void _applySearchFilter() {
    setState(() {
      filteredItems = allItems.where((item) {
        final itemName = item['item']?.toLowerCase() ?? '';
        return itemName.contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(
        title: "Admin Dashboard",
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isLoading) ...[
                const Center(child: CircularProgressIndicator()), // Show a loading spinner while metrics are loading
              ] else ...[
                // Horizontal carousel for filter buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterButton("All", 'all', totalItems),
                      const SizedBox(width: 16),
                      _buildFilterButton("Approved", 'approved', itemsApproved),
                      const SizedBox(width: 16),
                      _buildFilterButton("Found", 'found', itemsFound),
                      const SizedBox(width: 16),
                      _buildFilterButton("Lost", 'lost', itemsLost),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    labelText: 'Search by Item Name',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18.0)),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredItems.length + (isPaginating ? 1 : 0), // Add 1 for the loading indicator at the end
                    itemBuilder: (context, index) {
                      if (index == filteredItems.length) {
                        return _buildLoadMoreButton();
                      }

                      final item = filteredItems[index].data() as Map<String, dynamic>;
                      return _buildListItem(item);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Filter button for the segmented control with the number of items on the right
  Widget _buildFilterButton(String title, String filterType, int count) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          currentFilter = filterType;
          allItems.clear();  // Clear the previous list before loading the new items
          filteredItems.clear(); // Clear filtered items as well
          lastDocument = null;  // Reset pagination
        });
        _loadMoreItems(); // Reload the items based on the selected filter
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: currentFilter == filterType ? Colors.blue : Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Adjust padding
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            '($count)', // Display count inside parentheses
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: _loadMoreItems,
        child: isPaginating
            ? const CircularProgressIndicator(color: Color.fromARGB(255, 250, 227, 222))
            : const Text("Load More Items"),
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> item) { //For now only status can click
    return GestureDetector(
      onTap: item['status'] == 'approved'
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AptScreen(itemId: item['id'], userRole: 'admin',),
                ),
              );
            }
          : null,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: item['photo_url'] != null && item['photo_url'].isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item['photo_url'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    ),
                  )
                : const Icon(Icons.image_not_supported),
          ),
          title: Text(item['item'] ?? 'Unknown Item',
            style: const TextStyle(
            fontWeight: FontWeight.bold, // Makes the text bold
          ),),  // Change here to use item name
          subtitle: Text(
            'Status: ${item['status']}\nDescription: ${item['description'] ?? "No description"}',
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}
