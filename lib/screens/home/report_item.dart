import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:utmlostnfound/appbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';  // Import uuid package

class ReportLostItemScreen extends StatefulWidget {
  const ReportLostItemScreen({super.key});

  @override
  _ReportLostItemScreenState createState() => _ReportLostItemScreenState();
}

class _ReportLostItemScreenState extends State<ReportLostItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _itemController = TextEditingController();
  final _contactController = TextEditingController(text: "+60");
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;

  File? _imageFile;
  String? _photoUrl;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _fetchLoggedInUserData();
  }

  Future<void> _fetchLoggedInUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        _userId = user.uid;
      });

      // Fetch user data from Firestore
      DocumentSnapshot userData =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userData.exists) {
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _contactController.text = userData['phone'] ?? '+60';
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _uploadPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera); // Use the camera

    if (pickedFile != null) {
      File file = File(pickedFile.path);

      try {
        // Cloudinary credentials
        const cloudName = "dqqb4c714";
        const uploadPreset = "pics_upload";

        final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

        var request = http.MultipartRequest('POST', uri);
        request.fields['upload_preset'] = uploadPreset;
        request.files.add(await http.MultipartFile.fromPath('file', file.path));

        var response = await request.send();
        if (response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          final jsonResponse = json.decode(responseData);

          setState(() {
            _photoUrl = jsonResponse['secure_url'];
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded successfully!')),
          );
        } else {
          throw Exception('Failed to upload photo to Cloudinary');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No photo taken!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Report Found Item",
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF9E6D5), // Soft pale peach
              Color(0xFFD5EAE8),
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            padding: const EdgeInsets.all(20.0),
            margin: const EdgeInsets.symmetric(horizontal: 15),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Item Details",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name Field
                    _buildField("Name", "Enter your name", _nameController),

                    // Item Field
                    _buildField("Item", "Enter item name", _itemController),

                    // Contact Field
                    _buildField(
                      "Contact",
                      "+60",
                      _contactController,
                      keyboardType: TextInputType.phone,
                    ),

                    // Location Field
                    _buildField("Location", "Enter location", _locationController),

                    // Date Field
                    const Text("Date:", style: TextStyle(fontSize: 16)),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: _selectedDate != null
                                ? "${_selectedDate!.toLocal()}".split(' ')[0]
                                : "Select date",
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            hintStyle: TextStyle(
                              fontStyle: FontStyle.normal,
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          validator: (value) {
                            if (_selectedDate == null) {
                              return 'Please select a date';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Description Field
                    const Text("Description:", style: TextStyle(fontSize: 16)),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Enter description",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        hintStyle: TextStyle(
                          fontStyle: FontStyle.normal,
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Upload Photo
                    const Text("Upload Photo:", style: TextStyle(fontSize: 16)),
                    const Text(
                      "(Upload if available)",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _uploadPhoto,
                      icon: const Icon(Icons.upload_file),
                      label: const Text("Upload Photo"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Submit and Reset Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              CollectionReference lostItems =
                                  FirebaseFirestore.instance.collection('lost_items');

                              try {
                                // Format the selected date to 'YYYY-MM-DD' format
                                final formattedDate = _selectedDate != null
                                    ? "${_selectedDate!.toLocal()}".split(' ')[0]
                                    : null;

                                // Create a custom UUID for the ID
                                var uuid = Uuid();
                                String customId = uuid.v4(); // Generate a custom ID

                                // Add the item with the custom ID
                                await lostItems.doc(customId).set({
                                  'id': customId, // Custom ID added here
                                  'name': _nameController.text,
                                  'item': _itemController.text,
                                  'contact': _contactController.text,
                                  'location': _locationController.text,
                                  'date': formattedDate, // Save only the formatted date
                                  'description': _descriptionController.text,
                                  'photo_url': _photoUrl,
                                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                                  'status': 'lost',
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Item reported successfully!')),
                                );

                                Navigator.pop(context); // Navigate back to the main page
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to report item: $e')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Submit"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to build text fields
  Widget _buildField(String label, String hint, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            hintStyle: TextStyle(
              fontStyle: FontStyle.normal,
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
