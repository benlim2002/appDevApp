import 'dart:io'; // For File handling when picking image
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // For picking images
import 'dart:convert'; 
import 'package:utmlostnfound/screens/home/home.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String? _name;
  String? _email;
  String? _phone;
  String? _faculty;
  String? _profilePicUrl;
  String? _selectedFaculty;



  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _facultyController = TextEditingController();
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
        _selectedFaculty = data?['faculty'];
        _profilePicUrl = data?['profileImage'];
        _nameController.text = _name ?? '';
        _phoneController.text = _phone ?? '';
        _facultyController.text = _faculty ?? ''; //check here
      });
    }
  }

  // Update profile information
  Future<void> _updateProfile() async {
    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'faculty': _selectedFaculty,
      });

      setState(() {
        _name = _nameController.text;
        _phone = _phoneController.text;
        _faculty = _selectedFaculty;
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
  }


  // Method to pick and upload image to Cloudinary
Future<void> _pickImage() async {
  final pickedFile = await _picker.pickImage(source: ImageSource.gallery); // Allow picking from gallery
  if (pickedFile != null) {
    File file = File(pickedFile.path); // Convert to File

    try {
      // Cloudinary credentials
      const cloudName = "dqqb4c714";  // Replace with your Cloudinary cloud name
      const uploadPreset = "pics_upload";  // Replace with your Cloudinary upload preset

      // Cloudinary API endpoint for image upload
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      var request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      // Send request to Cloudinary
      var response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);

        setState(() {
          _profilePicUrl = jsonResponse['secure_url']; // Update with Cloudinary URL
        });

        // Update Firestore with the new profile picture URL
        await _firestore.collection('users').doc(_user!.uid).update({
          'profileImage': _profilePicUrl, // Update Firestore document
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

  // Show success dialog
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
                    const SizedBox(height: 25),

                    // Non-editable Email Field
                    if (_email != null)
                      _buildNonEditableField('Email', _email!),

                    // Editable profile fields
                    _buildEditableTextField('Name', _nameController),
                    _buildEditableTextField('Phone', _phoneController),
                    _buildFacultyDropdown(),

                    const SizedBox(height: 35),

                    // Update Profile button
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

                    const SizedBox(height: 20),

                    const Center( 
                      child: Text(
                        'Change Password',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password change section
                    _buildPasswordTextField('Enter old password', _oldPasswordController, _isOldPasswordObscure),
                    _buildPasswordTextField('Enter new password', _newPasswordController, _isNewPasswordObscure),
                    _buildPasswordTextField('Confirm new password', _confirmNewPasswordController, _isConfirmNewPasswordObscure),

                    const SizedBox(height: 25),

                    // Submit button to change password
                    Center(
                      child: SizedBox(
                        width: 300, 
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

 Widget _buildNonEditableField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
 Widget _buildEditableTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
Widget _buildFacultyDropdown() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Faculty', style: TextStyle(fontSize: 13)),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _selectedFaculty,
          items: [
            'Faculty of Computing',
            'Faculty of Civil Engineering',
            'Faculty of Mechanical Engineering',
            'Faculty of Electrical Engineering',
            'Faculty of Chemical and Energy Engineering',
            'Faculty of Science',
            'Faculty of Built Environment and Surveying',
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
            fillColor: const Color.fromARGB(255, 253, 253, 253),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildPasswordTextField(
      String label, TextEditingController controller, bool isObscure) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
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
    );
  }
}