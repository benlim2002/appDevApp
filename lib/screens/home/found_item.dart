import 'package:flutter/material.dart';
import 'package:utmlostnfound/appbar.dart'; 

class FoundItemScreen extends StatelessWidget {
  final List<Map<String, dynamic>> foundItems = [
    {
      'user': 'choong.b@graduate',
      'time': '1:38 p.m., 22/10/24',
      'image': 'assets/debit_card.png', // Replace with your image path
      'title': 'CIMB Debit Card',
      'location': 'WA3, KDSE, UTM',
      'description': 'A CIMB debit card found outside Blok WA3 at KDSE, please contact as soon as possible.',
    },
    {
      'user': 'izzmir@graduate',
      'time': '2:13 p.m., 24/10/24',
      'image': 'assets/keychains.png', // Replace with your image path
      'title': 'Keys with Cute Keychains',
      'location': 'Arked Angkasa, KTDI',
      'description': 'A cute key with keychains found at a green table at Arked Angkasa, KTDI, at 2pm.',
    },
  ];

  FoundItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Found Item",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFFFE6E6),
              Color(0xFFDFFFD6),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Search Field
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search Item Found",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: (value) {
                  // Handle search functionality
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: foundItems.length,
                itemBuilder: (context, index) {
                  final item = foundItems[index];
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
                          // User info and time
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: AssetImage(item['image']),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['user'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown[800],
                                    ),
                                  ),
                                  Text(
                                    item['time'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Item image
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: AssetImage(item['image']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Item details
                          Text(
                            item['title'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item['location'],
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item['description'],
                            style: const TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(height: 10),

                          // Contact Button
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                // Handle contact action
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown[400],
                              ),
                              child: const Text("Contact"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
