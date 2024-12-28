// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:utmlostnfound/appbar.dart';
import 'package:utmlostnfound/screens/home/item_details.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  _MyPostsScreenState createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userName;
  String? userPhone;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc.data()?['name'];
          userPhone = userDoc.data()?['phone'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "My Unverified Posts",
      ),
      body: userName == null || userPhone == null
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFF9E6D5), // Soft pale peach
                    Color(0xFFD5EAE8),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('items')
                    .where('name', isEqualTo: userName)
                    .where('contact', isEqualTo: userPhone)
                    .where('verification', isEqualTo: 'no')
                    .where('postType', whereIn: ['Found', 'Lost'])
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No unverified posts found."),
                    );
                  }

                  final posts = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final data = post.data() as Map<String, dynamic>;

                      return MyPostCard(data: data, postId: post.id);
                    },
                  );
                },
              ),
            ),
    );
  }
}

class MyPostCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String postId;

  const MyPostCard({Key? key, required this.data, required this.postId}) : super(key: key);

  @override
  _MyPostCardState createState() => _MyPostCardState();
}

class _MyPostCardState extends State<MyPostCard> {
  void _deletePost() async {
    try {
      await FirebaseFirestore.instance.collection('items').doc(widget.postId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting post: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item image placeholder or actual image
            if (data['photo_url'] != null && data['photo_url'] != '')
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    data['photo_url'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 50,
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 10),
            
            // Item details
            Text(
              data['item'] ?? 'Unknown Item',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              data['location'] ?? 'No location provided',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 5),
            Text(
              data['description'] ?? 'No description provided',
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 5),
            Text(
              'Post Type: ${data['postType'] ?? 'Unknown'}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 10),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDetailsScreen(
                          item: data, // Pass the selected item's data
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[400],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("See More"),
                ),
                ElevatedButton(
                  onPressed: _deletePost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Delete"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}