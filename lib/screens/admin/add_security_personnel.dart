import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:utmlostnfound/screens/admin/admin_appbar.dart';  // Import the AdminAppBar
import 'package:utmlostnfound/screens/admin/view_users.dart'; // Import the view_users screen

class AddSecurityPersonnelScreen extends StatefulWidget {
  const AddSecurityPersonnelScreen({Key? key}) : super(key: key);

  @override
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
  bool _isPasswordObscure = true;

  File? _imageFile;
  String? _photoUrl;

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
          'photo_url': photoUrl,
          'role': 'security', 
          'created_at': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Security personnel added successfully!")),
        );

        // Navigate to the security page of view_users.dart
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ViewUsersScreen(), // Pass 'security' role to the ViewUsersScreen
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AdminAppBar(
        title: "Add Security Personnel",
        scaffoldKey: _scaffoldKey,
      ),
      drawer: AdminAppBar(
        title: "",
        scaffoldKey: _scaffoldKey,
      ).buildDrawer(context),
      body: SingleChildScrollView( // Wrap with SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              width: 325, // Narrowing the form by setting a fixed width
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Enter Details',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Photo upload section
                  const Text('Profile Photo (Optional)'),
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

                  const Text('Name'),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter security personnel\'s name',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  const Text('Email'),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Enter email',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  const Text('Password'),
                  TextField(
                    controller: _passwordController,
                    obscureText: _isPasswordObscure,
                    decoration: InputDecoration(
                      hintText: 'Enter password',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordObscure
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _isPasswordObscure = !_isPasswordObscure;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _addSecurityPersonnel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 250, 227, 222),
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                      ),
                      child: const Text('Add Security Personnel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
