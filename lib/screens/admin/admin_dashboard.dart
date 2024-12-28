// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:utmlostnfound/screens/admin/admin_appbar.dart'; // Import AdminAppBar
// ignore: unused_import
import 'package:utmlostnfound/aptScreen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

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
  int itemsCollected = 0;
  int itemsApproved = 0;

  bool isLoading = true;
  bool isPaginating = false;
  DocumentSnapshot? lastDocument;
  List<DocumentSnapshot> allItems = [];
  List<DocumentSnapshot> filteredItems = []; // List for filtered items
  String currentFilter = 'Found';
  String? selectedLocation; // Define selectedLocation
  DateTimeRange? selectedDateRange; // Define selectedDateRange
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  final List<String> locations = [
    'Arked Meranti',
    'Arked Cengal',
    'Arked Angkasa',
    'Arked Kolej 13',
    'Arked Kolej 9 & 10',
    'Arked Bangunan Persatuan Pelajar',
    'Arked Kolej Perdana'
    'Faculty of Computing',
    'Faculty of Civil Engineering',
    'Faculty of Mechanical Engineering',
    'Faculty of Electrical Engineering',
    'Faculty of Chemical and Energy Engineering',
    'Faculty of Science',
    'Faculty of Built Environment and Surveying',
    'Faculty of Management',
    'Faculty of Social Sciences and Humanities'
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


  Future<Uint8List> _generateCertificate(String finderName, String date, String item, String aptMadeBy ) async {
    
    final ByteData bytes = await rootBundle.load('assets/home.png'); // Path to your asset
    final Uint8List imageData = bytes.buffer.asUint8List();
    
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Image(
                pw.MemoryImage(imageData),
                height: 200, // Adjust height
                width: 200,  // Adjust width
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Certificate of Appreciation',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'This certificate is awarded to',
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                finderName,
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'For their honesty and contribution to the UTM Lost & Found community',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'on reporting and handing in the lost item of $item on $date that belonged to $aptMadeBy.',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
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
    final pdfBytes = await pdf.save();

    return pdfBytes;

  }


  Future<void> _uploadPdfToCloudinary(Uint8List pdfBytes, String finderName, String item) async {
    try {
      // Cloudinary API details
      String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dqqb4c714/raw/upload";
      String uploadPreset = "pdf_upload";

      // Convert PDF bytes to base64
      String base64Pdf = base64Encode(pdfBytes);

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl));
      request.fields['file'] = 'data:application/pdf;base64,$base64Pdf';
      request.fields['upload_preset'] = uploadPreset;
      request.fields['timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();

      // Send request
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);
        String downloadUrl = jsonResponse['secure_url'];
        print('PDF uploaded successfully. Download URL: $downloadUrl');

        // Save the PDF URL to the user's document in Firestore
        await _savePdfUrlToFirestore(downloadUrl, finderName);
        await _savePdfUrlToItemsCollection(downloadUrl, item, finderName);

      } else {
        print('Error uploading PDF to Cloudinary: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading PDF: $e');
    }
  }

  Future<void> _savePdfUrlToItemsCollection(String downloadUrl, String item, String finderName) async {
  try {

    print('Saving PDF URL to items collection');
    print('Item Name: $item');
    print('Finder Name: $finderName');
    print('Download URL: $downloadUrl');

    // Step 1: Query Firestore to get the document ID of the item with the matching item name and finder name
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('items')
        .where('item', isEqualTo: item)
        .where('name', isEqualTo: finderName) // Change 'finderName' if you're using a different field
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Step 2: Extract the document ID
      String itemDocId = querySnapshot.docs.first.id;
      print('Found item document ID: $itemDocId');

      // Step 3: Update the item's document with the certificate URL
      await FirebaseFirestore.instance.collection('items').doc(itemDocId).update({
        'certificateUrl': downloadUrl,
        'updatedAt': Timestamp.now(),
      }).then((value) {
        print('Certificate URL added successfully to item document');
      }).catchError((error) {
        print('Error adding certificate URL to item document: $error');
      });
    } else {
      print('No item found with the given item name and finder name');
    }
  } catch (e) {
    print('Error saving PDF URL to Firestore: $e');
  }
}

  Future<void> _savePdfUrlToFirestore(String downloadUrl, String finderName) async {
    try {
      // Step 1: Query Firestore to get the document ID of the user with the matching finderName
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: finderName) // Change 'name' if you're using a different field
          .get();
          

      if (querySnapshot.docs.isNotEmpty) {
        // Step 2: Extract the document ID
        String userDocId = querySnapshot.docs.first.id;
        print('Found user document ID: $userDocId');


        // Step 3: Update the user's document with the certificate URL
      await FirebaseFirestore.instance.collection('users').doc(userDocId).collection('certificates').add({
        'certificateUrl': downloadUrl,
        'createdAt': Timestamp.now(),
      }).then((value) {
        print('Certificate added successfully');
      }).catchError((error) {
        print('Error adding certificate: $error');
      });
      } else {
        print('No user found with the given finderName');
      }
    } catch (e) {
      print('Error saving PDF URL to Firestore: $e');
    }
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
                _updatePostType(itemId, 'Found', '');
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


void _showPdf(String pdfUrl) async {
  try {
    // Debugging: Print the URL
    print('PDF URL: $pdfUrl');

    // Validate the URL
    if (pdfUrl.isEmpty || !Uri.parse(pdfUrl).isAbsolute) {
      throw 'Invalid PDF URL';
    }

    // Download the PDF file
    final response = await http.get(Uri.parse(pdfUrl));
    final bytes = response.bodyBytes;

    // Get the temporary directory
    final dir = await getTemporaryDirectory();

    // Create a temporary file
    final file = File('${dir.path}/temp.pdf');

    // Write the PDF file to the temporary file
    await file.writeAsBytes(bytes);

    // Display the PDF
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFView(
          filePath: file.path,
        ),
      ),
    );
  } catch (e) {
    print('Error displaying PDF: $e');
  }
}

  void _showItemDetails(BuildContext context, Map<String, dynamic> item) {
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
                    if (item['photo_url'] != null && item['photo_url'].isNotEmpty)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.0), // Adjust the radius as needed
                          child: Image.network(
                            item['photo_url'],
                            height: 400,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      item['item'] ?? 'Unknown Item',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Location: ${item['location'] ?? 'No location provided'}',
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Area: ${item['faculty'] ?? 'No location provided'}',
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Description: ${item['description'] ?? 'Unknown'}',
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: ${item['postType'] ?? 'Unknown'}',
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    if (item['postType'] == 'approved') ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Retrival Info:',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                      Text(
                        'Retriever: ${item['aptMadeBy'] ?? "N/A"}',
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date: ${item['aptDate'] != null ? DateFormat('yyyy-MM-dd').format((item['aptDate'] as Timestamp).toDate()) : "N/A"}',
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Time: ${item['aptDate'] != null ? DateFormat('HH:mm:ss').format((item['aptDate'] as Timestamp).toDate()) : "N/A"}',
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                    if (item['postType'] == 'collected') ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Certificate Generated to:',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                      Text(
                        'Founder: ${item['name'] ?? "N/A"}',
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Contact: ${item['contact'] ?? "N/A"}',
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showConfirmCollectionDialog(BuildContext context, String id, String finderName, String item, String date, String aptMadeBy) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Collection'),
          content: const Text(
            'Is the retriever here for their item? Proceed to generate e-certificate for the founder?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                // First, generate the certificate
                Uint8List pdfBytes = await _generateCertificate(finderName, date, item, aptMadeBy);

                // Upload the PDF to Cloudinary and update Firestore
                await _uploadPdfToCloudinary(pdfBytes, finderName, item);

                await _updatePostType(id, 'collected', ''); // Pass an empty string or the appropriate certificate URL

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Certificate generated and uploaded successfully')),
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


  Future<void> _updatePostType(String itemId, String newPostType, String certificateUrl) async {
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
      final collectedSnapshot = await _firestore
          .collection('items')
          .where('postType', isEqualTo: 'collected')
          .get();

      setState(() {
        totalItems = totalSnapshot.docs.length;
        itemsFound = foundSnapshot.docs.length;
        itemsLost = lostSnapshot.docs.length;
        itemsApproved = approvedSnapshot.docs.length;
        itemsCollected = collectedSnapshot.docs.length;
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
            .limit(100)
            .get();
      } else {
        querySnapshot = await _firestore
            .collection('items')
            .where('postType', isEqualTo: filterStatus)
            .orderBy('date', descending: true)
            .limit(100)
            .get();
      }
    } else {
      if (filterStatus == 'all') {
        querySnapshot = await _firestore
            .collection('items')
            .orderBy('date', descending: true)
            .startAfterDocument(lastDocument!)
            .limit(100)
            .get();
      } else {
        querySnapshot = await _firestore
            .collection('items')
            .where('postType', isEqualTo: filterStatus)
            .orderBy('date', descending: true)
            .startAfterDocument(lastDocument!)
            .limit(100)
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
      final itemLocation = item['faculty'] ?? '';
      final itemDateStr = item['date'] as String?;
      DateTime? itemDate;
      
      try {
        itemDate = itemDateStr != null ? DateTime.parse(itemDateStr) : null;
      } catch (e) {
        print('Error parsing date: $e');
      }

      bool matchesSearch = itemName.contains(searchQuery.toLowerCase());
      bool matchesLocation = selectedLocation == null || itemLocation == selectedLocation;
      bool matchesDateRange = selectedDateRange == null || 
        (itemDate != null && 
         itemDate.isAfter(selectedDateRange!.start) && 
         itemDate.isBefore(selectedDateRange!.end));
      
      return matchesSearch && matchesLocation && matchesDateRange;
    }).toList();
  });
}

  void _showFilterPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Options'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select Location'),
                      value: selectedLocation,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Locations'),
                        ),
                        ...locations.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedLocation = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final DateTimeRange? picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: selectedDateRange,
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDateRange = picked;
                          });
                        }
                      },
                      child: Text(selectedDateRange == null 
                        ? 'Select Date Range'
                        : '${selectedDateRange!.start.toString().substring(0, 10)} - ${selectedDateRange!.end.toString().substring(0, 10)}'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedLocation = null;
                      selectedDateRange = null;
                    });
                  },
                  child: const Text('Clear Filters'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _applySearchFilter();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
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
                      _buildFilterButton("Collected", 'collected', itemsCollected),
                      const SizedBox(width: 16),
                      _buildFilterButton("All", 'all', totalItems),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Search bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          labelText: 'Search by Item Name',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(35.0)),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Badge(
                        isLabelVisible: selectedLocation != null || selectedDateRange != null,
                        child: const Icon(Icons.filter_list),
                      ),
                      onPressed: _showFilterPopup,
                    ),
                  ],
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
          _showConfirmCollectionDialog(context, item['id'], item['name'], item['item'], item['date'], item['aptMadeBy']);
        } else if (item['postType'] == 'collected') {
          _showPdf(item['certificateUrl']);
        }
      },
      onLongPress: () {
        _showItemDetails(context, item);
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
              if (item['postType'] == 'approved') ...[
                const SizedBox(height: 4),
                Text('Retriever: ${item['aptMadeBy'] ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Date: ${item['aptDate'] != null ? DateFormat('yyyy-MM-dd').format((item['aptDate'] as Timestamp).toDate()) : "N/A"}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Time: ${item['aptDate'] != null ? DateFormat('HH:mm:ss').format((item['aptDate'] as Timestamp).toDate()) : "N/A"}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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