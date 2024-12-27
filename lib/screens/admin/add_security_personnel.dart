import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:utmlostnfound/screens/admin/admin_appbar.dart';  // Import the AdminAppBar

class AddSecurityPersonnelScreen extends StatefulWidget {
  const AddSecurityPersonnelScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddSecurityPersonnelScreenState createState() =>
      _AddSecurityPersonnelScreenState();
}

class _AddSecurityPersonnelScreenState
    extends State<AddSecurityPersonnelScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _photoUrlController = TextEditingController();
  // ignore: unused_field
  final bool _isPasswordObscure = true;

  File? _imageFile;
  String? _photoUrl;
   String? _selectedWorkArea;

  Future<void> _uploadPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

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

          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded successfully!')),
          );
        } else {
          throw Exception('Failed to upload photo to Cloudinary');
        }
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e')),
        );
      }
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No photo selected!')),
      );
    }
  }

  Future<void> _addSecurityPersonnel() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final photoUrl = _photoUrl ?? ''; // Use uploaded photo URL

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showErrorDialog("All fields are required.");
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
              email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'profileImage': photoUrl,
          'workArea': _selectedWorkArea,
          'role': 'security', 
          'created_at': FieldValue.serverTimestamp(),
        });

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Security personnel added successfully!")),
        );

        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _photoUrlController.clear();
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label, String hint, TextEditingController controller,
    {TextInputType keyboardType = TextInputType.text}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "$label:",
        style: const TextStyle(fontSize: 16),
      ),
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
          hintStyle: TextStyle( // Customize the hint text style here
            fontStyle: FontStyle.normal,
            fontSize: 14,
            color: Colors.grey[500], // Lighter color for the hint
          ),
        ),
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter ${label.toLowerCase()}';
          }
          return null;
        },
      ),
      const SizedBox(height: 15),
    ],
  );
}

Widget _buildWorkAreaField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Area:", // Label for the dropdown
        style: TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 5),
      Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          value: _selectedWorkArea,
          items: [
              'Front Gate',
              'KTDI',
              'KTR',
              'KDSE',
              'KTF',
              'K9K10',
              'KDOJ',
          ].map((faculty) => DropdownMenuItem(
            value: faculty,
            child: Text(faculty),
          )).toList(),
          onChanged: (value) {
            setState(() {
              _selectedWorkArea = value;
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
    ],
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Assign the scaffold key to the Scaffold
      appBar: AdminAppBar(
        title: "Add Security Personnel", // Title of the AppBar
        scaffoldKey: _scaffoldKey, // Pass the scaffold key to AdminAppBar
      ),
      // No need to manually call buildDrawer here, it's handled inside AdminAppBar
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF9E6D5), // Soft pale peach
              Color(0xFFD5EAE8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Optional: Adjust padding here
          child: Column(
            children: [
              const SizedBox(height: 0), // Remove extra space here

              // Centered container that holds the form and profile section
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity, // Ensures it spans the available width
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, spreadRadius: 2),
                      ],
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // Center align the content
                        children: [
                          const SizedBox(height: 20), // Reduce space before "Enter Details"
                          const Text(
                            'Enter Details',
                            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                          // Profile Photo section centered
                          GestureDetector(
                            onTap: _uploadPhoto,
                            child: _imageFile == null
                                ? Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[200],
                                    ),
                                    child: const Icon(Icons.camera_alt, size: 40),
                                  )
                                : Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      image: DecorationImage(
                                        image: FileImage(_imageFile!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 15),

                          // Form fields with reduced space above them
                          _buildField("Name", "Enter security personnel's name", _nameController),
                          _buildWorkAreaField(),
                          _buildField("Email", "Enter email", _emailController),
                          _buildField("Password", "Enter password", _passwordController),
                          
                          const SizedBox(height: 20),

                          // Add Security Personnel button
                          ElevatedButton(
                            onPressed: _addSecurityPersonnel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 250, 227, 222),
                              padding: const EdgeInsets.symmetric(horizontal: 30),
                            ),
                            child: const Text('Add Security Personnel'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
