import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:utmlostnfound/main.dart';
import 'package:utmlostnfound/screens/home/profile.dart'; // Make sure to import your ProfileScreen here

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({super.key, required this.title});

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
    switch (value) {
      case 'profile':
        // Navigate to ProfileScreen when Profile is selected
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()), // Navigate to ProfileScreen
        );
        break;
      case 'settings':
        // Add navigation to Settings page here
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Navigating to Settings")),
        );
        break;
      case 'logout':
        _handleLogout(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the app's TextTheme for the title and PopupMenuItems
    final TextTheme textTheme = Theme.of(context).textTheme;

    return AppBar(
      title: Text(
        title,
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900, // Make the title bold
          fontSize: 26, // Optional: increase font size for more emphasis
          letterSpacing: 0.1,
        ),
      ),
      centerTitle: true,
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) => _onMenuSelected(context, value),
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem(
                value: 'profile',
                child: Text(
                  "Profile",
                  style: textTheme.bodyMedium, // Use bodyText2 style for consistency
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Text(
                  "Settings",
                  style: textTheme.bodyMedium, // Use bodyText2 style for consistency
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text(
                  "Logout",
                  style: textTheme.bodyMedium, // Use bodyText2 style for consistency
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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
