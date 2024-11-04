import 'package:flutter/material.dart';
import 'package:flutter_application_1/aft_login.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;
  String? _selectedFaculty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/lost_found_logo.png', // Update with your asset's path
                      width: 40,
                      height: 40,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'UTM LOST & FOUND',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40),

                // Registration Box
                Container(
                  padding: EdgeInsets.all(20),
                  margin: EdgeInsets.symmetric(horizontal: 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
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
                      SizedBox(height: 20),

                      // Name Field
                      Text('Name'),
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
                      SizedBox(height: 10),

                      // ID Number Field
                      Text('ID Number'),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter your ID number',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),

                      // Register Number Field
                      Text('Register Number'),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter your register number',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),

                      // Faculty Dropdown
                      Text('Faculty'),
                      DropdownButtonFormField<String>(
                        value: _selectedFaculty,
                        items: ['Faculty 1', 'Faculty 2', 'Faculty 3'] // Add your options
                            .map((faculty) => DropdownMenuItem(
                                  value: faculty,
                                  child: Text(faculty),
                                ))
                            .toList(),
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
                      SizedBox(height: 10),

                      // Phone Number Field
                      Text('Phone Number'),
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
                      SizedBox(height: 10),

                      // Username Field
                      Text('User Name'),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter your username',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),

                      // Password Field
                      Text('Password'),
                      TextField(
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
                      SizedBox(height: 10),

                      // Confirm Password Field
                      Text('Confirm Password'),
                      TextField(
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
                                _isConfirmPasswordObscure =
                                    !_isConfirmPasswordObscure;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Submit Button
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                              Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LostAndFoundScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 250, 227, 222),
                            padding: EdgeInsets.symmetric(horizontal: 30),
                          ),
                          child: Text('Submit'),
                        ),
                      ),
                      SizedBox(height: 10),

                      // Sign In Link
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Navigate back to login
                          },
                          child: Text(
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
