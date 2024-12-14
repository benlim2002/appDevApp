import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:utmlostnfound/screens/home/profile.dart';  // Import ProfileScreen here
import 'package:utmlostnfound/main.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onTitleTap;  // Make onTitleTap nullable and optional

  const CustomAppBar({
    super.key,
    required this.title,
    this.onTitleTap, // Make it optional with a nullable type
  });

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
      case 'settings':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Navigating to Settings")),
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
        onTap: onTitleTap, // Only trigger onTap if onTitleTap is provided
        child: Text(
          title,
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
              if (isUserSignedIn) ...[
                PopupMenuItem(
                  value: 'profile',
                  child: Text(
                    "Profile",
                    style: textTheme.bodyMedium,
                  ),
                ),
              ] else ...[
                PopupMenuItem(
                  value: 'profile',
                  child: GestureDetector(
                    onTap: () {
                      _showSignInDialog(context);  // Show dialog for profile
                    },
                    child: Text(
                      "Profile (Sign In Required)",
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,  // Inactive text color
                      ),
                    ),
                  ),
                ),
              ],
              PopupMenuItem(
                value: 'settings',
                child: Text(
                  "Settings",
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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
