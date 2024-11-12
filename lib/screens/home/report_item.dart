import 'package:flutter/material.dart';
import 'package:utmlostnfound/appbar.dart'; 

class ReportLostItemScreen extends StatefulWidget {
  const ReportLostItemScreen({super.key});

  @override
  _ReportLostItemScreenState createState() => _ReportLostItemScreenState();
}

class _ReportLostItemScreenState extends State<ReportLostItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _itemController = TextEditingController();
  final _contactController = TextEditingController(text: "+60");
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;

  // Function to handle Date selection
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Report Lost Item",
        style: TextStyle(fontWeight: FontWeight.bold), image: '',
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name Field
                const Text("Name:", style: TextStyle(fontSize: 16)),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: "Enter your name",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Item Field
                const Text("Item:", style: TextStyle(fontSize: 16)),
                TextFormField(
                  controller: _itemController,
                  decoration: InputDecoration(
                    hintText: "Enter item name",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the item name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Contact Field
                const Text("Contact:", style: TextStyle(fontSize: 16)),
                TextFormField(
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: "+60",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your contact number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Location Field
                const Text("Location:", style: TextStyle(fontSize: 16)),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: "Enter location",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Date Field
                const Text("Date:", style: TextStyle(fontSize: 16)),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: _selectedDate != null
                            ? "${_selectedDate!.toLocal()}".split(' ')[0]
                            : "Select date",
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      validator: (value) {
                        if (_selectedDate == null) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Description Field
                const Text("Description:", style: TextStyle(fontSize: 16)),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Enter description",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                // Upload Photo Field
                const Text("Upload Photo:", style: TextStyle(fontSize: 16)),
                const Text(
                  "(Upload if available)",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    // Handle file upload here
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Upload Photo"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black, backgroundColor: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 30),

                // Submit and Reset Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Handle submit action here
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Item reported successfully!')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text("Submit"),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        _formKey.currentState?.reset();
                        _nameController.clear();
                        _itemController.clear();
                        _contactController.clear();
                        _locationController.clear();
                        _descriptionController.clear();
                        setState(() {
                          _selectedDate = null;
                        });
                      },
                      child: const Text("Reset"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
