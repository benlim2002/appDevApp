import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;
  String? _selectedFaculty;
  File? _profileImage;
  String? _photoUrl;
  


  // Method to pick an image from the gallery
  Future<void> _pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery); // You can use camera or gallery

  if (pickedFile != null) {
    File file = File(pickedFile.path);

    try {
      // Cloudinary credentials
      const cloudName = "dqqb4c714";  // your Cloudinary cloud name
      const uploadPreset = "pics_upload";  // your Cloudinary upload preset

      final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      var request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);

        setState(() {
          _photoUrl = jsonResponse['secure_url']; // save the Cloudinary URL
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


  Future<void> _registerUser() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text;
  final confirmPassword = _confirmPasswordController.text;
  final name = _nameController.text.trim();
  final phone = _phoneController.text.trim();

  // Email validation: Check if the email ends with the appropriate UTM domains
  if (!email.endsWith("@graduate.utm.my") && !email.endsWith("@utm.my")) {
    _showErrorDialog("Please use a valid UTM email address (either @graduate.utm.my or @utm.my).");
    return;
  }

  // Password and confirm password validation
  if (password != confirmPassword) {
    _showErrorDialog("Passwords do not match.");
    return;
  }

  // Determine the role based on the email domain
  String role = '';
  if (email.endsWith("@graduate.utm.my")) {
    role = 'student'; // Student role for @graduate.utm.my
  } else if (email.endsWith("@utm.my")) {
    role = 'staff'; // Staff role for @utm.my
  }

  try {
    // Register the user with Firebase Auth
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    User? user = userCredential.user;

    if (user != null) {
      // Send email verification
      await user.sendEmailVerification();

      // Store user data in Firestore with the determined role
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'faculty': _selectedFaculty,
        'role': role, // Store the role (student or staff)
        'profileImage': _photoUrl, // Store the Cloudinary URL
      });

      // Show a dialog instructing the user to verify their email
      _showVerificationDialog();
    }
  } catch (e) {
    _showErrorDialog(e.toString());
  }
}



  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Verify Your Email"),
        content: const Text("A verification email has been sent. Please verify your email before logging in."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Navigate back to the login screen
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Registration Error"),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
             Color(0xFFF9E6D5), // Soft pale peach
             Color(0xFFD5EAE8),// Light green color
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Add Image Picker here
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: _profileImage == null
                              ? const Icon(Icons.add_a_photo, size: 30)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), // Space below image picker
                    
                    const Text('Name'),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        hintStyle: TextStyle(
                            fontStyle: FontStyle.normal,
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text('Email'),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Enter your UTM email',
                        hintStyle: TextStyle(
                            fontStyle: FontStyle.normal,
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text('Faculty'),
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
                          'Faculty of Social Sciences and Humanities'
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
                    const Text('Phone Number'),
                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        hintText: 'Enter your phone number',
                        hintStyle: TextStyle(
                            fontStyle: FontStyle.normal,
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text('Password'),
                    TextField(
                      controller: _passwordController,
                      obscureText: _isPasswordObscure,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: TextStyle(
                            fontStyle: FontStyle.normal,
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.5),
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
                    const SizedBox(height: 15),
                    const Text('Confirm Password'),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _isConfirmPasswordObscure,
                      decoration: InputDecoration(
                        hintText: 'Confirm your password',
                        hintStyle: TextStyle(
                            fontStyle: FontStyle.normal,
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.5),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_isConfirmPasswordObscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordObscure = !_isConfirmPasswordObscure;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 250, 227, 222),
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                        ),
                        child: const Text('Submit'),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Navigate back to login
                        },
                        child: const Text(
                          'Already have an account? Sign in',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
