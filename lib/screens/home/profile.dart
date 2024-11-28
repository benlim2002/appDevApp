import 'dart:io'; // For File handling when picking image
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmlostnfound/screens/home/home.dart';  // Import the HomeScreen
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:firebase_storage/firebase_storage.dart'; // For uploading images to Firebase

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? _user;
  String? _name;
  String? _email;
  String? _phone;
  String? _faculty;
  String? _profilePicUrl;

  // Controllers for password change
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

  // Load user data from Firestore and Firebase Storage
  Future<void> _loadUserData() async {
    if (_user != null) {
      final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      final data = userDoc.data();
      setState(() {
        _name = data?['name'];
        _email = data?['email'];
        _phone = data?['phone'];
        _faculty = data?['faculty'];
        _profilePicUrl = data?['profilePicUrl']; // Load profile pic URL
      });
    }
  }

  // Method to change password
  Future<void> _changePassword() async {
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmNewPassword = _confirmNewPasswordController.text;

    if (newPassword != confirmNewPassword) {
      _showErrorDialog("New passwords do not match.");
      return;
    }

    try {
      // Re-authenticate the user
      final cred = EmailAuthProvider.credential(
        email: _user!.email!,
        password: oldPassword,
      );
      await _user!.reauthenticateWithCredential(cred);

      // Update password
      await _user!.updatePassword(newPassword);
      _showSuccessDialog("Password updated successfully.");
    } catch (e) {
      _showErrorDialog("Error: ${e.toString()}");
    }
  }

  // Method to pick a new profile picture
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      // Upload the new profile picture to Firebase Storage
      _uploadProfilePic();
    }
  }

  // Upload profile picture to Firebase Storage
  Future<void> _uploadProfilePic() async {
    if (_image != null) {
      try {
        final fileName = '${_user!.uid}_profile_pic.jpg';
        final ref = _storage.ref().child('profile_pictures').child(fileName);
        await ref.putFile(_image!);
        final downloadUrl = await ref.getDownloadURL();

        // Update Firestore with the new profile picture URL
        await _firestore.collection('users').doc(_user!.uid).update({
          'profilePicUrl': downloadUrl,
        });

        setState(() {
          _profilePicUrl = downloadUrl;
        });

      } catch (e) {
        _showErrorDialog("Error uploading profile picture: ${e.toString()}");
      }
    }
  }

  // Show error dialog
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

  // Show success dialog and navigate to HomeScreen
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LostAndFoundScreen()), // Navigate to HomeScreen
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
              Color(0xFFF9E6D5), // Soft pale peach
              Color(0xFFD5EAE8), // Light green color
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
                        'Profile',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Profile picture section
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
                    const SizedBox(height: 20),

                    // Display profile information
                    _buildProfileInfo('Name :', _name),
                    _buildProfileInfo('Email :', _email),
                    _buildProfileInfo('Phone :', _phone),
                    _buildProfileInfo('Faculty :', _faculty),

                    const SizedBox(height: 35),

                    const Center( // Center the "Change Password" text
                      child: Text(
                        'Change Password',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Wrap the TextField in a Center widget to center it, and use a Container to adjust its width
                    Center(
                      child: SizedBox(
                        width: 250, // Adjust this width value as needed
                        child: TextField(
                          controller: _oldPasswordController,
                          obscureText: _isOldPasswordObscure,
                          decoration: InputDecoration(
                            hintText: 'Enter old password',
                            hintStyle: TextStyle(
                            fontStyle: FontStyle.normal,
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(_isOldPasswordObscure ? Icons.visibility_off : Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  _isOldPasswordObscure = !_isOldPasswordObscure;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    Center(
                      child: SizedBox(
                        width: 250, // Adjust this width value as needed
                        child: TextField(
                          controller: _newPasswordController,
                          obscureText: _isNewPasswordObscure,
                          decoration: InputDecoration(
                            hintText: 'Enter new password',
                            hintStyle: TextStyle(
                            fontStyle: FontStyle.normal,
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(_isNewPasswordObscure ? Icons.visibility_off : Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  _isNewPasswordObscure = !_isNewPasswordObscure;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    Center(
                      child: SizedBox(
                        width: 250, // Adjust this width value as needed
                        child: TextField(
                          controller: _confirmNewPasswordController,
                          obscureText: _isConfirmNewPasswordObscure,
                          decoration: InputDecoration(
                            hintText: 'Confirm new password',
                            hintStyle: TextStyle(
                            fontStyle: FontStyle.normal,
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(_isConfirmNewPasswordObscure ? Icons.visibility_off : Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  _isConfirmNewPasswordObscure = !_isConfirmNewPasswordObscure;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Submit button to change password
                    Center(
                      child: SizedBox(
                        width: 300, // Adjust width for the button
                        child: ElevatedButton(
                          onPressed: _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 250, 227, 222),
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                          ),
                          child: const Text('Change Password'),
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

  // Helper function to build profile info text fields
  Widget _buildProfileInfo(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Center( // Center the widget horizontally
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center the row content
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 15), // Add spacing between label and value
          Text(value ?? 'Not available', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}