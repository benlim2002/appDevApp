import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:utmlostnfound/screens/admin/admin_dashboard.dart'; // Admin Dashboard screen
import 'package:utmlostnfound/screens/admin/approval.dart'; // Approval screen
import 'package:utmlostnfound/main.dart'; // Your main app entry
import 'package:utmlostnfound/screens/admin/view_users.dart';
import 'package:utmlostnfound/screens/admin/add_security_personnel.dart';

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
        // Navigate to Profile screen (implement this screen if necessary)
        break;
      case 'settings':
        // Navigate to Settings screen (implement this screen if necessary)
        break;
      case 'logout':
        _handleLogout(context);
        break;
    }
  }

  // Drawer for Admin
  Widget buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Admin Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            title: const Text('Admin Dashboard'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboard()),
              );
            },
          ),
          ListTile(
            title: const Text('Approval'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ApprovalScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('View Users'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ViewUsersScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Add Security Personnel'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddSecurityPersonnelScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => scaffoldKey.currentState?.openDrawer(), // Open drawer when menu icon is pressed
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
