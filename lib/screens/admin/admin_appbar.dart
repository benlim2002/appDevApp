import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:utmlostnfound/screens/admin/admin_dashboard.dart'; // Admin Dashboard screen
import 'package:utmlostnfound/screens/admin/appointment.dart'; // Approval screen
import 'package:utmlostnfound/main.dart'; // Your main app entry
import 'package:utmlostnfound/screens/admin/view_users.dart';
import 'package:utmlostnfound/screens/admin/add_security_personnel.dart';
import 'package:utmlostnfound/screens/home/profile.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const AdminAppBar({super.key, required this.title, required this.scaffoldKey});

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You have successfully logged out")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error logging out: $e")),
        );
      }
    }
  }

  // Handle popup menu selection (for Profile, Settings, Logout)
  void _onMenuSelected(BuildContext context, String value) {
    switch (value) {
      case 'profile':
        Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()), // Replace `ProfileScreen` with the actual Profile screen widget
      );
        break;
      case 'settings':
        // Navigate to Settings screen (implement this screen if necessary)
        break;
      case 'logout':
        _handleLogout(context);
        break;
    }
  }

  // BottomSheet for Admin menu with improved layout and styling
  void _showAdminMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Ensure that the BottomSheet is not too large
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuItem(context, 'Admin Dashboard', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminDashboard()),
                );
              }),
              _buildMenuItem(context, 'Appointments', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AppointmentScreen()),
                );
              }),
              _buildMenuItem(context, 'View Users', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ViewUsersScreen()),
                );
              }),
              _buildMenuItem(context, 'Add Security Personnel', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddSecurityPersonnelScreen()),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // Helper method to create the menu items with a common style
  Widget _buildMenuItem(BuildContext context, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2F4F4F), // Darker text color for better readability
        ),
      ),
      onTap: onTap,
      tileColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black, // Set title text color to black globally
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black),
        onPressed: () => _showAdminMenu(context), // Open BottomSheet when menu icon is pressed
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) => _onMenuSelected(context, value),
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem(
                value: 'profile',
                child: Text("Profile"),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text("Settings"),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text("Logout"),
              ),
            ];
          },
          color: Colors.white, // Set background color of popup menu
          elevation: 8, // Add some shadow to the menu
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
