// ignore_for_file: library_private_types_in_public_api, unused_field, use_build_context_synchronously

import 'dart:io'; // For File handling when picking image
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // For picking images
import 'dart:convert'; 
import 'package:utmlostnfound/screens/home/home.dart'; 

class SecurityProfileScreen extends StatefulWidget {
  const SecurityProfileScreen({super.key});

  @override
  _SecurityProfileScreenState createState() => _SecurityProfileScreenState();
}

class _SecurityProfileScreenState extends State<SecurityProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String? _name;
  String? _email;
  String? _phone;
  String? _workArea;
  String? _profilePicUrl;
  String? _selectedWorkArea;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  bool _isOldPasswordObscure = true;
  bool _isNewPasswordObscure = true;
  bool _isConfirmNewPasswordObscure = true;

  final ImagePicker _picker = ImagePicker();
  File? _image;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadUserData();
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    if (_user != null) {
      final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      final data = userDoc.data();
      setState(() {
        _name = data?['name'];
        _email = data?['email'];
        _phone = data?['phone'];
        _selectedWorkArea = data?['workArea'];
        _profilePicUrl = data?['profileImage'];
        _nameController.text = _name ?? '';
        _phoneController.text = _phone ?? '';
      });
    }
  }

  // Update profile information
  Future<void> _updateProfile() async {
    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'workArea': _selectedWorkArea,
      });
      
      
      final oldPassword = _oldPasswordController.text;
      final newPassword = _newPasswordController.text;
      final confirmNewPassword = _confirmNewPasswordController.text;

      if (newPassword != confirmNewPassword) {
        _showErrorDialog("New passwords do not match.");
        return;
      }

      try {
        final cred = EmailAuthProvider.credential(
          email: _user!.email!,
          password: oldPassword,
        );
        await _user!.reauthenticateWithCredential(cred);
        await _user!.updatePassword(newPassword);
        _showSuccessDialog("Password updated successfully.");
      } catch (e) {
        _showErrorDialog("Error: ${e.toString()}");
      }

      setState(() {
        _name = _nameController.text;
        _phone = _phoneController.text;
        _workArea = _selectedWorkArea;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }


  // Method to pick and upload image to Cloudinary
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File file = File(pickedFile.path);

      try {
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
            _profilePicUrl = jsonResponse['secure_url'];
          });

          await _firestore.collection('users').doc(_user!.uid).update({
            'profileImage': _profilePicUrl,
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LostAndFoundScreen()),
              );
            },
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
              Color(0xFFF9E6D5), 
              Color(0xFFD5EAE8),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
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
                        'Security Profile',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: _profilePicUrl != null
                              ? NetworkImage(_profilePicUrl!)
                              : const AssetImage('assets/default_profile.png') as ImageProvider,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    if (_email != null)
                      _buildNonEditableField('Email', _email!),

                    _buildEditableTextField('Name', _nameController),
                    _buildEditableTextField('Phone', _phoneController),
                    _buildWorkAreaDropdown(),
                    _buildPasswordTextField('Enter old password', _oldPasswordController, _isOldPasswordObscure),
                    _buildPasswordTextField('Enter new password', _newPasswordController, _isNewPasswordObscure),
                    _buildPasswordTextField('Confirm new password', _confirmNewPasswordController, _isConfirmNewPasswordObscure),

                    const SizedBox(height: 35),

                    Center(
                      child: SizedBox(
                        width: 300,
                        child: ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD5EAE8),
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                          ),
                          child: const Text('Update Profile'),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


Widget _buildNonEditableField(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, // Set background to white
        borderRadius: BorderRadius.circular(8), // Match rounded corners
        border: Border.all(color: Colors.grey.withOpacity(0.4)), // Lighter border like in the screenshot
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10), // Space between label and value
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, color: Colors.black54), // Slightly faded value text
              overflow: TextOverflow.ellipsis, // In case value overflows
              maxLines: 1, // Limit text to 1 line
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildEditableTextField(String label, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white, // Set background to white
        borderRadius: BorderRadius.circular(8), // Rounded corners
        border: Border.all(color: Colors.grey.withOpacity(0.4)), // Lighter border like non-editable field
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: InputBorder.none, // Remove the default input border
                hintText: 'Enter your $label', // Add hint text to guide the user
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildWorkAreaDropdown() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white, // Set background to white
        borderRadius: BorderRadius.circular(8), // Rounded corners
        border: Border.all(color: Colors.grey.withOpacity(0.4)), // Lighter border like the TextField
      ),
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
          contentPadding: EdgeInsets.zero, // Remove extra padding from the input field
          border: InputBorder.none, // Remove the default input border
        ),
      ),
    ),
  );
}
  
Widget _buildPasswordTextField(
      String label, TextEditingController controller, bool isObscure) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white, // Set background to white
          borderRadius: BorderRadius.circular(8), // Rounded corners
          border: Border.all(color: Colors.grey.withOpacity(0.4)), // Lighter border like the Dropdown
        ),
        child: TextField(
          controller: controller,
          obscureText: isObscure,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), // Match label style
            border: InputBorder.none, // Remove default border to match the container's border
            suffixIcon: IconButton(
              icon: Icon(
                isObscure ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  if (label == 'Enter old password') {
                    _isOldPasswordObscure = !_isOldPasswordObscure;
                  } else if (label == 'Enter new password') {
                    _isNewPasswordObscure = !_isNewPasswordObscure;
                  } else {
                    _isConfirmNewPasswordObscure = !_isConfirmNewPasswordObscure;
                  }
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}