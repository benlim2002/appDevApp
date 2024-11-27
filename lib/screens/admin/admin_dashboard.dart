import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:utmlostnfound/screens/admin/admin_appbar.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int totalItems = 0;
  int itemsFound = 0;
  int itemsLost = 0;

  bool isLoading = true;
  bool isPaginating = false; // To handle pagination loading state
  DocumentSnapshot? lastDocument; // Last document for pagination
  List<DocumentSnapshot> allItems = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardMetrics();
    _loadMoreItems();  // Load the first batch of items immediately
  }

  // Load metrics like total, found, and lost items
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

      setState(() {
        totalItems = totalSnapshot.docs.length;
        itemsFound = foundSnapshot.docs.length;
        itemsLost = lostSnapshot.docs.length;
        isLoading = false; // Data loaded
      });
    } catch (error) {
      print('Error loading metrics: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch paginated data
  Future<void> _loadMoreItems() async {
    if (isPaginating) return; // Prevent multiple calls at once

    setState(() {
      isPaginating = true;
    });

    QuerySnapshot querySnapshot;

    if (lastDocument == null) {
      querySnapshot = await _firestore
          .collection('lost_items')
          .orderBy('date', descending: true)
          .limit(20)
          .get();
    } else {
      querySnapshot = await _firestore
          .collection('lost_items')
          .orderBy('date', descending: true)
          .startAfterDocument(lastDocument!)
          .limit(20)
          .get();
    }

    if (querySnapshot.docs.isNotEmpty) {
      lastDocument = querySnapshot.docs.last;
      allItems.addAll(querySnapshot.docs);
    }

    setState(() {
      isPaginating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AdminAppBar(
        title: "Admin Dashboard",
        scaffoldKey: _scaffoldKey,
      ),
      drawer: AdminAppBar(title: "", scaffoldKey: _scaffoldKey).buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isLoading) ...[
              const Center(child: CircularProgressIndicator()), // Show a loading spinner while metrics are loading
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMetricCard("Total Items", totalItems),
                  _buildMetricCard("Items Found", itemsFound),
                  _buildMetricCard("Items Lost", itemsLost),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: allItems.length + 1, // Add 1 for the "Load More" button
                  itemBuilder: (context, index) {
                    if (index == allItems.length) {
                      return _buildLoadMoreButton();
                    }

                    final item = allItems[index].data() as Map<String, dynamic>;
                    return _buildListItem(item);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, int value) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // Load more button to trigger pagination
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

  // List item display
  Widget _buildListItem(Map<String, dynamic> item) {
  return Card(
    elevation: 2,
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: ListTile(
      leading: Padding(
        padding: const EdgeInsets.only(top: 10.0), // Adjust this value to move the image lower
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
      title: Text(item['name'] ?? 'Unknown Item'),
      subtitle: Text(
        'Status: ${item['status']}\nDescription: ${item['description'] ?? "No description"}',
      ),
        isThreeLine: true,
      ),
    );
  }
}