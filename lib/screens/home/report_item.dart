// ignore_for_file: unused_field, library_private_types_in_public_api, use_build_context_synchronously

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:utmlostnfound/appbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart'; // Import uuid package

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
  String? _selectedFaculty;
  String? _postType = 'Lost'; // Default value for Post Type

  // ignore: duplicate_ignore
  // ignore: unused_field
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
        title: "Report Item",
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

                    // Post Type (Lost or Found)
                    const Text("Post Type", style: TextStyle(fontSize: 16)),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _postType = 'Lost';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _postType == 'Lost'
                                  ? const Color.fromARGB(255, 75, 247, 144)
                                  : Colors.grey[300],
                              foregroundColor: Colors.black,
                            ),
                            child: const Text("Lost"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _postType = 'Found';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _postType == 'Found'
                                  ? const Color.fromARGB(255, 75, 247, 144)
                                  : Colors.grey[300],
                              foregroundColor: Colors.black,
                            ),
                            child: const Text("Found"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Other Input Fields
                    _buildField("Name", "Enter your name", _nameController),
                    _buildField("Item", "Enter item name", _itemController),
                    _buildField(
                      "Contact",
                      "+60",
                      _contactController,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildField("Location", "Enter location", _locationController),
                    const Text('Faculty', style: TextStyle(fontSize: 16)),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedFaculty,
                        items: [
                              'Faculty of Computing', 
                              'Faculty of Civil Engineering', 
                              'Faculty of Mechanical Engineering', 
                              'Faculty of Electrical Engineering', 
                              'Faculty of Chemical and Energy Engineering', 
                              'Faculty of Science', 
                              'Faculty of Built Environment and Surveying ', 
                              'Faculty of Management',
                              'Faculty of Social Sciences and Humanities',
                              'Kolej Tun Fatimah',
                              'Kolej Tun Razak',
                              'Kolej Perdana',
                              'Kolej 9 & 10',
                              'Kolej Datin Seri Endon',
                              'Kolej Dato Onn Jaafar',
                              'Kolej Tun Hussien Onn',
                              'Kolej Tuanku Canselor',
                              'Kolej Rahman Putra',
                              'Arked Meranti',
                              'Arked Cengal',
                              'Arked Angkasa',
                              'Arked Kolej 13',
                              'Arked Kolej 9 & 10',
                              'Arked Bangunan Persatuan Pelajar',
                              'Arked Kolej Perdana'
                        ].map((faculty) => DropdownMenuItem(
                          value: faculty,
                          child: Text(faculty),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFaculty = value;
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text("Date", style: TextStyle(fontSize: 16)),
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
                            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
                    // Description Field
                   const Text("Brief Description", style: TextStyle(fontSize: 16)),
                   const SizedBox(height: 5),
                   const Text(
                      "(Brand, Size, Colour, etc)",
                       style: TextStyle(fontSize: 12, color: Colors.grey),
                       ),
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
                            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ),


                    // Upload Photo
                    const SizedBox(height: 15),
                    const Text("Upload Photo", style: TextStyle(fontSize: 16)),
                    ElevatedButton.icon(
                      onPressed: _uploadPhoto,
                      icon: const Icon(Icons.upload_file),
                      label: const Text("Upload Photo"),
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
                                  FirebaseFirestore.instance.collection('items');

                              try {
                                final formattedDate = _selectedDate != null
                                    ? "${_selectedDate!.toLocal()}".split(' ')[0]
                                    : null;

                                var uuid = const Uuid();
                                String customId = uuid.v4();

                                await lostItems.doc(customId).set({
                                  'id': customId,
                                  'name': _nameController.text,
                                  'item': _itemController.text,
                                  'contact': _contactController.text,
                                  'location': _locationController.text,
                                  'faculty': _selectedFaculty,
                                  'description': _descriptionController.text,
                                  'postType': _postType,
                                  'date': formattedDate,
                                  'verification': "no",
                                  'photo_url': _photoUrl,
                                  'createdAt': FieldValue.serverTimestamp(),
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Item reported successfully!')),
                                );

                                Navigator.pop(context);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue, // Background color for Submit button
                            foregroundColor: Colors.white, // Text color for Submit button
                          ),
                          child: const Text('Submit'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _nameController.clear();
                            _itemController.clear();
                            _contactController.clear();
                            _locationController.clear();
                            _descriptionController.clear();
                            setState(() {
                              _postType = 'Lost';
                              _selectedDate = null;
                              _photoUrl = null;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red, // Background color for Reset button
                            foregroundColor: Colors.white, // Text color for Reset button
                          ),
                          child: const Text('Reset'),
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

  Widget _buildField(String label, String hint, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            keyboardType: keyboardType,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '$label is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
