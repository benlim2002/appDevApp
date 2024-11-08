import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:utmlostnfound/screens/home/aft_login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;
  String? _selectedFaculty;

  Future<void> _registerUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Email and password validation
    if (!email.endsWith("@graduate.utm.my")) {
      _showErrorDialog("Please use an email ending with '@graduate.utm.my'.");
      return;
    }
    if (password != confirmPassword) {
      _showErrorDialog("Passwords do not match.");
      return;
    }

    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LostAndFoundScreen()),
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    }
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE6E6), // Light pink color
              Color(0xFFDFFFD6), // Light green color
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and Title Row
              /*  Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/lost_found_logo.png', // Update with your asset's path
                      width: 40,
                      height: 40,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'UTM LOST & FOUND',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                  ],
                ),*/
                const SizedBox(height: 40),
                
                // Registration Box
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

                      // Name Field
                      const Text('Name'),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter your name',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),



                       // Email Field
                      const Text('Email'),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'Enter your UTM email',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),


                      // Faculty Dropdown
                      const Text('Faculty'),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400), // Adjust maxWidth as needed
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
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Phone Number Field
                      const Text('Phone Number'),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter your phone number',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                  

                      // Password Field
                      const Text('Password'),
                      TextField(
                        controller: _passwordController,
                        obscureText: _isPasswordObscure,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
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
                      const SizedBox(height: 15),

                      // Confirm Password Field
                      const Text('Confirm Password'),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _isConfirmPasswordObscure,
                        decoration: InputDecoration(
                          hintText: 'Confirm your password',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
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

                      // Submit Button
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

                      // Sign In Link
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
      ),
    );
  }
}
