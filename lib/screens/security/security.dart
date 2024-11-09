import 'package:flutter/material.dart';
import 'package:utmlostnfound/appbar.dart';  // Make sure CustomAppBar is imported

class SecurityScreen extends StatelessWidget {
  // Mock data for demonstration
  final List<Map<String, String>> items = [
    {
      'name': 'Lost Wallet',
      'contact': '+60123456789',
      'location': 'Library',
      'date': '2024-11-01',
      'description': 'A black leather wallet containing ID and cards',
      'photoUrl': 'https://via.placeholder.com/100',
    },
    {
      'name': 'Lost Keys',
      'contact': '+60129876543',
      'location': 'Gym',
      'date': '2024-11-02',
      'description': 'A set of car keys with a red keychain',
      'photoUrl': 'https://via.placeholder.com/100',
    },
    {
      'name': 'Found Phone',
      'contact': '+60134567890',
      'location': 'Cafeteria',
      'date': '2024-11-03',
      'description': 'An iPhone with a cracked screen',
      'photoUrl': '',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(  // Replacing default AppBar with CustomAppBar
        title: "Security Personnel Dashboard",  // Customize the title if needed
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: item['photoUrl'] != null && item['photoUrl']!.isNotEmpty
                  ? Image.network(item['photoUrl']!)
                  : const Icon(Icons.image_not_supported),
              title: Text(item['name']!),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text("Contact: ${item['contact']}"),
                  Text("Location: ${item['location']}"),
                  Text("Date: ${item['date']}"),
                  Text("Description: ${item['description']}"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
