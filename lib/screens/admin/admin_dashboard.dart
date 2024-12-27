// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pdf/pdf.dart';
import 'package:utmlostnfound/screens/admin/admin_appbar.dart'; // Import AdminAppBar
// ignore: unused_import
import 'package:utmlostnfound/aptScreen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  // ignore: library_private_types_in_public_api
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
  String currentFilter = 'Found'; 
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadDashboardMetrics();
    _loadMoreItems();  
  }

  void _showVerificationDialog(String itemId, String verificationStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Verify Item Received'),
          content: verificationStatus == "no"
              ? const Text('Do you want to verify that this item has been secured?')
              : const Text('This item is already verified.'),
          actions: <Widget>[
            if (verificationStatus == "no") ...[
              TextButton(
                onPressed: () {
                  _updateItemVerificationStatus(itemId, "yes");
                  Navigator.of(context).pop();
                },
                child: const Text('Verify'),
              ),
            ],
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateItemVerificationStatus(String itemId, String verificationStatus) async {
    try {

      await FirebaseFirestore.instance
          .collection('items')
          .doc(itemId)
          .update({
        'verification': verificationStatus, // Mark the item as verified
      });

      // Optionally, update the local list of items to reflect the change
      setState(() {
        allItems = allItems.map((item) {
          if (item['id'] == itemId) {
            item['verification'] == verificationStatus;  // Update verification status
          }
          return item;
        }).toList();
      });

      // Show a confirmation message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item has been verified')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error verifying the item')),
      );
    }
  }

  Future<void> _markAsCollected(String itemId) async {
    try {
      await FirebaseFirestore.instance
          .collection('items')
          .doc(itemId)
          .update({'collectionStatus': 'collected'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collection confirmed')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming collection: $error')),
      );
    }
  }


  Future<void> _generateCertificate(String finderName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'Certificate of Appreciation',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'This certificate is awarded to',
                style: pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                finderName,
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'For their honesty and contribution to the UTM Lost & Found community.',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'UTM Lost & Found Team',
                style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );

    // Show the generated PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }


  void _showChangePostTypeDialog(String itemId, String currentPostType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Status'),
          content: const Text('Select a new post type for this item:'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Update the postType to "Found" in Firestore
                _updatePostType(itemId, 'Found');
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Found'),
            ),
            TextButton(
              onPressed: () {
                // Cancel and close the dialog
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmCollectionDialog(String itemId, String finderName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Collection'),
          content: const Text(
            'Generate e-certificate for the founder?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _generateCertificate(finderName);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Certificate generated successfully')),
                );
              },
              child: const Text('Confirm'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _updatePostType(String itemId, String newPostType) async {
    try {
      // Update the postType field in Firestore
      await FirebaseFirestore.instance
          .collection('items') 
          .doc(itemId)  
          .update({
            'postType': newPostType, 
          });

      setState(() {
        allItems = allItems.map((item) {
          if (item['id'] == itemId) {
            item['postType'] == newPostType; 
          }
          return item;
        }).toList();
      });

      // Optionally, apply search filter again to show updated items
      _applySearchFilter();

      // Show a confirmation message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post type updated to $newPostType')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating post type')),
      );
    }
  }


  Future<void> _loadDashboardMetrics() async {
    try {
      final totalSnapshot = await _firestore.collection('items').get();
      final foundSnapshot = await _firestore
          .collection('items')
          .where('postType', isEqualTo: 'Found')
          .get();
      final lostSnapshot = await _firestore
          .collection('items')
          .where('postType', isEqualTo: 'Lost')
          .get();
      final approvedSnapshot = await _firestore
          .collection('items')
          .where('postType', isEqualTo: 'approved')
          .get();

      setState(() {
        totalItems = totalSnapshot.docs.length;
        itemsFound = foundSnapshot.docs.length;
        itemsLost = lostSnapshot.docs.length;
        itemsApproved = approvedSnapshot.docs.length;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dashboard data: $error')),
      );
    }
  }

  Future<void> _loadMoreItems() async {
    if (isPaginating) return;

    setState(() {
      isPaginating = true;
    });

    QuerySnapshot querySnapshot;
    String filterStatus = currentFilter == 'all' ? 'all' : currentFilter;

    if (lastDocument == null) {
      if (filterStatus == 'all') {
        querySnapshot = await _firestore
            .collection('items')
            .orderBy('date', descending: true)
            .limit(20)
            .get();
      } else {
        querySnapshot = await _firestore
            .collection('items')
            .where('postType', isEqualTo: filterStatus)
            .orderBy('date', descending: true)
            .limit(20)
            .get();
      }
    } else {
      if (filterStatus == 'all') {
        querySnapshot = await _firestore
            .collection('items')
            .orderBy('date', descending: true)
            .startAfterDocument(lastDocument!)
            .limit(20)
            .get();
      } else {
        querySnapshot = await _firestore
            .collection('items')
            .where('postType', isEqualTo: filterStatus)
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
                      _buildFilterButton("Found", 'Found', itemsFound),
                      const SizedBox(width: 16),
                      _buildFilterButton("Lost", 'Lost', itemsLost),
                      const SizedBox(width: 16),
                      _buildFilterButton("Approved", 'approved', itemsApproved),
                      const SizedBox(width: 16),
                      _buildFilterButton("All", 'all', totalItems),
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

  Widget _buildListItem(Map<String, dynamic> item) {
  String verificationStatus = item['verification'] ?? "no"; // Check the verification status

  return GestureDetector(
      onTap: () {
        if (item['postType'] == 'Found' && verificationStatus == "no") {
          _showVerificationDialog(item['id'], verificationStatus);
        } else if (item['postType'] == 'Lost') {
          _showChangePostTypeDialog(item['id'], item['postType']);
        } else if (item['postType'] == 'approved') {
          _showConfirmCollectionDialog(item['id'], item['postType']);
        }
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: item['photo_url'] != null && item['photo_url'].isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item['photo_url'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    ),
                  ),
                )
              : null,
          title: Text(
            item['item'] ?? 'Unknown Item',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: ${item['postType']}'),
              Text('Description: ${item['description'] ?? "No description"}'),
              if (item['postType'] == 'Found') ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      verificationStatus == 'yes' ? Icons.check_circle : Icons.error,
                      color: verificationStatus == 'yes' ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      verificationStatus == 'yes' ? 'Verified' : 'Not Verified',
                      style: TextStyle(
                        color: verificationStatus == 'yes' ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}