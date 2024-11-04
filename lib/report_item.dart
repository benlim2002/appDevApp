import 'package:flutter/material.dart';


class ReportLostItemScreen extends StatefulWidget {
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
    if (picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Report Lost Item"),
        backgroundColor: Colors.brown[800],
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE6E6),
              Color(0xFFDFFFD6),
            ],
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name Field
                Text("Name:", style: TextStyle(fontSize: 16)),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: "Enter your name",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),

                // Item Field
                Text("Item:", style: TextStyle(fontSize: 16)),
                TextFormField(
                  controller: _itemController,
                  decoration: InputDecoration(
                    hintText: "Enter item name",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the item name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),

                // Contact Field
                Text("Contact:", style: TextStyle(fontSize: 16)),
                TextFormField(
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: "+60",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your contact number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),

                // Location Field
                Text("Location:", style: TextStyle(fontSize: 16)),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: "Enter location",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the location';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),

                // Date Field
                Text("Date:", style: TextStyle(fontSize: 16)),
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
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
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
                SizedBox(height: 15),

                // Description Field
                Text("Description:", style: TextStyle(fontSize: 16)),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Enter description",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 15),

                // Upload Photo Field
                Text("Upload Photo:", style: TextStyle(fontSize: 16)),
                Text(
                  "(Upload if available)",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    // Handle file upload here
                  },
                  icon: Icon(Icons.upload_file),
                  label: Text("Upload Photo"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black, backgroundColor: Colors.grey[300],
                  ),
                ),
                SizedBox(height: 30),

                // Submit and Reset Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Handle submit action here
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Item reported successfully!')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: Text("Submit"),
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
                      child: Text("Reset"),
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
