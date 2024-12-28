// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmlostnfound/screens/home/profile.dart';
import 'package:utmlostnfound/screens/home/certificates.dart';
import 'package:utmlostnfound/screens/home/appointments.dart'; 
import 'package:utmlostnfound/main.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onTitleTap;  // Make onTitleTap nullable and optional

  const CustomAppBar({
    super.key,
    required this.title,
    this.onTitleTap, // Make it optional with a nullable type
  });

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  String? userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        setState(() {
          userRole = userDoc.data()?['role'];
        });
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final bool? logoutConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (logoutConfirmed == true) {
      try {
        await FirebaseAuth.instance.signOut();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MyApp()),
          (Route<dynamic> route) => false,
        );

        Future.delayed(Duration.zero, () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You have successfully logged out")),
          );
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error logging out: $e")),
        );
      }
    }
  }

  void _onMenuSelected(BuildContext context, String value) {
    final currentUser = FirebaseAuth.instance.currentUser;

    switch (value) {
      case 'profile':
        if (currentUser == null) {
          _showSignInDialog(context);  // Show dialog when not signed in
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        }
        break;
      case 'appointments':
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppointmentsScreen()),
          );
        break;
      case 'certificates':
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CertificatesScreen()),
          );
        break;
      case 'logout':
        _handleLogout(context);
        break;
    }
  }

  void _showSignInDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sign In Required"),
        content: const Text("You must be signed in to access the profile."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    bool isUserSignedIn = FirebaseAuth.instance.currentUser != null;

    return AppBar(
      title: GestureDetector(
        onTap: widget.onTitleTap, // Only trigger onTap if onTitleTap is provided
        child: Text(
          widget.title,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 26,
            letterSpacing: 0.1,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) => _onMenuSelected(context, value),
          itemBuilder: (BuildContext context) {
            return [
              if (isUserSignedIn && userRole != 'guest') ...[
                PopupMenuItem(
                  value: 'profile',
                  child: Text(
                    "Profile",
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
              PopupMenuItem(
                value: 'appointments',
                child: Text(
                  "Appointments",
                  style: textTheme.bodyMedium,
                ),
              ),
              PopupMenuItem(
                value: 'certificates',
                child: Text(
                  "Certificates",
                  style: textTheme.bodyMedium,
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text(
                  "Logout",
                  style: textTheme.bodyMedium,
                ),
              ),
            ];
          },
        ),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 242, 234, 243)],
            begin: Alignment.center,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }
}