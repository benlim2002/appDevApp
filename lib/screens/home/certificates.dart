import 'dart:io';
import 'package:cloudinary_url_gen/transformation/region.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:utmlostnfound/appbar.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  _CertificatesScreenState createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  String? userId;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
  }

  Future<void> _fetchUserId() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        userId = currentUser.uid;
      });
    }
  }

  Future<void> _showPdf(String pdfUrl) async {
    try {
      // Debugging: Print the URL
      print('PDF URL: $pdfUrl');

      // Validate the URL
      if (pdfUrl.isEmpty || !Uri.parse(pdfUrl).isAbsolute) {
        throw 'Invalid PDF URL';
      }

      // Download the PDF file
      final response = await http.get(Uri.parse(pdfUrl));
      final bytes = response.bodyBytes;

      // Get the temporary directory
      final dir = await getTemporaryDirectory();

      // Create a temporary file
      final file = File('${dir.path}/temp.pdf');

      // Write the PDF file to the temporary file
      await file.writeAsBytes(bytes);

      // Display the PDF
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFView(
            filePath: file.path,
          ),
        ),
      );
    } catch (e) {
      print('Error displaying PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Certificates",
      ),
      body: userId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('certificates')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No certificates found."),
                  );
                }

                final certificates = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: certificates.length,
                  itemBuilder: (context, index) {
                    final certificate = certificates[index];
                    final data = certificate.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      child: ListTile(
                        title: Text(
                          'Certificate ${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Issued on: ${data['createdAt']?.toDate().toString().substring(0, 10) ?? 'Unknown'}',
                        ),
                        trailing: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        onTap: () {
                          _showPdf(data['certificateUrl']);
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}