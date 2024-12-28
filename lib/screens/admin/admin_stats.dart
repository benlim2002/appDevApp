// ignore_for_file: use_build_context_synchronously, unused_local_variable

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:utmlostnfound/screens/admin/admin_appbar.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
// ignore: unused_import
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';

class AdminStatistics extends StatefulWidget {
  const AdminStatistics({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AdminStatisticsState createState() => _AdminStatisticsState();
}

class _AdminStatisticsState extends State<AdminStatistics> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, int> facultyLostCounts = {};
  Map<String, int> timeLostCounts = {};
  bool isLoading = true;
  String currentGraph = 'Faculty'; // Track which graph is being displayed
  String currentPeriod = ''; // Current selected period (e.g., "Month")
  
  final Map<String, String> facultyMapping = {
  'Faculty of Computing': 'FC',
  'Faculty of Civil Engineering': 'FCE',
  'Faculty of Mechanical Engineering': 'FME',
  'Faculty of Electrical Engineering': 'FEE',
  'Faculty of Chemical and Energy Engineering': 'FCEE',
  'Faculty of Science': 'FS',
  'Faculty of Built Environment and Surveying': 'FBES',
  'Faculty of Management': 'FM',
  'Faculty of Social Sciences and Humanities': 'FSSH',
  'Kolej Tun Dr. Ismail': 'KTDI',
  'Kolej Tun Fatimah': 'KTF',
  'Kolej Tun Razak': 'KTR',
  'Kolej Perdana': 'KP',
  'Kolej 9 & 10': 'K910',
  'Kolej Datin Seri Endon': 'KDSE',
  'Kolej Dato Onn Jaafar': 'KDOJ',
  'Kolej Tun Hussien Onn': 'KTHO',
  'Kolej Tuanku Canselor': 'KTC',
  'Kolej Rahman Putra': 'KRP',
  'Arked Meranti': 'AM',
  'Arked Cengal': 'AC',
  'Arked Angkasa': 'AA',
  'Arked Kolej 13': 'AK13',
  'Arked Kolej 9 & 10': 'AK910',
  'Arked Bangunan Persatuan Pelajar': 'ABPP',
  'Arked Kolej Perdana': 'AKP',
  };

  @override
  void initState() {
    super.initState();
    _fetchFacultyLostCounts();
  }

  // Fetch data for lost items per faculty
  Future<void> _fetchFacultyLostCounts() async {
    try {
      Map<String, int> counts = {};
      for (String fullName in facultyMapping.keys) {
        if ((currentGraph == 'Faculty' && fullName.startsWith('Faculty')) ||
            (currentGraph == 'Kolej' && fullName.startsWith('Kolej')) ||
            (currentGraph == 'Arked' && fullName.startsWith('Arked'))) {
          final snapshot = await _firestore
              .collection('items')
              .where('faculty', isEqualTo: fullName)
              .get();
          String abbreviation = facultyMapping[fullName]!;
          counts[abbreviation] = snapshot.docs.length;
        }
      }
      setState(() {
        facultyLostCounts = counts;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch data for lost items by month (using createdAt as Timestamp)
  Future<void> _fetchTimeLostCountsForSelectedMonth(DateTime selectedDate) async {
    try {
      Map<String, int> counts = {};
      DateTime startOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
      DateTime endOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);

      QuerySnapshot snapshot = await _firestore.collection('items').get();

    
      for (var doc in snapshot.docs) {
        Timestamp createdAtTimestamp = doc['createdAt']; 

        DateTime createdAtDate = createdAtTimestamp.toDate();

      
        if (createdAtDate.isAfter(startOfMonth) && createdAtDate.isBefore(endOfMonth)) {
          String dateKey = DateFormat('yyyy-MM-dd').format(createdAtDate);

          counts[dateKey] = (counts[dateKey] ?? 0) + 1;
        }
      }

      setState(() {
        timeLostCounts = counts;
        currentPeriod = 'Month: ${DateFormat('MMMM yyyy').format(selectedDate)}';
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildChart() {
    if (currentGraph == 'Faculty') {
      return _buildBarChart(facultyLostCounts);
    } else if (currentGraph == 'Kolej') {
      return _buildBarChart(facultyLostCounts);
    } else if (currentGraph == 'Arked') {
      return _buildBarChart(facultyLostCounts);
    } else {
      return _buildLineChart(timeLostCounts);
    }
  }

  // Show Month Picker
  void _selectMonth() async {
    final DateTime? selectedMonth = await showMonthPicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedMonth != null) {
      setState(() {
        currentPeriod = 'Month: ${DateFormat('MMMM yyyy').format(selectedMonth)}';
        isLoading = true;
        _fetchTimeLostCountsForSelectedMonth(selectedMonth); // Pass the selected month
      });
    }
  }

  // Show Graph Options (Faculty vs. Month)
  void _showGraphOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text(
              'Lost Items - Faculty',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              setState(() {
                currentGraph = 'Faculty';
                isLoading = true;
                _fetchFacultyLostCounts();
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text(
              'Lost Items - Kolej',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              setState(() {
                currentGraph = 'Kolej';
                isLoading = true;
                _fetchFacultyLostCounts();
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text(
              'Lost Items - Arked',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              setState(() {
                currentGraph = 'Arked';
                isLoading = true;
                _fetchFacultyLostCounts();
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text(
              'Lost Items - Month',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              setState(() {
                currentGraph = 'Month';
                isLoading = true;
              });
              Navigator.pop(context);
              // Show month picker after selecting "Lost Items per Month"
              _selectMonth();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(Map<String, int> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text("No data available for the selected period."),
      );
    }

    // Parse the keys as DateTime objects from the 'yyyy-MM-dd' format
    List<DateTime> dates = data.keys.map((key) {
      return DateFormat('yyyy-MM-dd').parse(key); // Parse the date string
    }).toList();
    dates.sort();

    // Generate a list of all days in the selected period
    DateTime firstDate = dates.first;
    DateTime lastDate = dates.last;
    List<DateTime> allDays = [];
    for (DateTime date = firstDate; date.isBefore(lastDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
      allDays.add(date);
    }

    // Map the data to the corresponding days
    List<FlSpot> spots = allDays.map((date) {
      String key = DateFormat('yyyy-MM-dd').format(date); // Convert date back to string format
      int value = data[key] ?? 0;
      return FlSpot(date.difference(firstDate).inDays.toDouble(), value.toDouble());
    }).toList();

    // Calculate interval, ensure it's not zero
    double interval = (lastDate.difference(firstDate).inDays / 5).roundToDouble();
    if (interval <= 0) {
      interval = 1; // Minimum interval to avoid assertion error
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            isCurved: false,
            spots: spots,
            color: Colors.deepPurpleAccent, // Single color for the line
            belowBarData: BarAreaData(
              show: true,
              color: Colors.deepPurpleAccent.withOpacity(0.3), // Color with opacity
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval, // Ensured to be non-zero
              getTitlesWidget: (value, meta) {
                int dayIndex = value.toInt();
                DateTime date = firstDate.add(Duration(days: dayIndex));
                return Text(
                  DateFormat('d').format(date),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        minX: 0,
        maxX: lastDate.difference(firstDate).inDays.toDouble(),
        minY: 0,
        maxY: (data.values.isNotEmpty
          ? (data.values.reduce((a, b) => a > b ? a : b) > 15
              ? data.values.reduce((a, b) => a > b ? a : b)
              : 15)
          : 0).toDouble(),
      ),
    );
  }

  // Build the Bar Chart widget for Lost Items per Faculty
  Widget _buildBarChart(Map<String, int> data) {
    List<String> keys = data.keys.toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (data.values.isNotEmpty
                ? data.values.reduce((a, b) => a > b ? a : b)
                : 1)
            .toDouble(),
        barGroups: keys
            .map((key) => BarChartGroupData(
                  x: keys.indexOf(key),
                  barRods: [
                    BarChartRodData(
                      toY: data[key]?.toDouble() ?? 0,
                      color: Colors.deepPurpleAccent,
                      width: 16,
                    ),
                  ],
                ))
            .toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < keys.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      keys[value.toInt()],
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }

  // Display the current selected period (Month)
  Widget _buildCurrentPeriodBar() {
    if (currentGraph == 'Faculty') {
      return const SizedBox.shrink();
    } else if (currentGraph == 'Kolej') {
      return const SizedBox.shrink();
    } else if (currentGraph == 'Arked') {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        _selectMonth(); // Call _selectMonth when tapped
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.deepPurpleAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          currentPeriod.isNotEmpty ? currentPeriod : 'Select period',
          style: const TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }


  // Export data to PDF
  Future<void> _exportToPDF(DateTime selectedDate) async {
  try {
    // Fetch all items data from Firestore
    QuerySnapshot snapshot = await _firestore.collection('items').get();

    // Prepare PDF data
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          // Extract and sort the data by date
          final data = snapshot.docs.map((doc) {
            Timestamp createdAtTimestamp = doc['createdAt'];
            DateTime createdAtDate = createdAtTimestamp.toDate();
            String dateKey = DateFormat('yyyy-MM-dd').format(createdAtDate);
            String item = doc['item'] ?? 'Unknown Item';
            return [dateKey, item];
          }).toList();

          // Sort the data by date
          data.sort((a, b) => a[0].compareTo(b[0]));

          // Add item number to the data
          final numberedData = data.asMap().entries.map((entry) {
            int index = entry.key + 1; // Start numbering from 1
            List<String> row = entry.value;
            return [index.toString(), ...row];
          }).toList();

          // Conditionally generate PDF content based on graph type
          if (currentGraph == 'Faculty' || currentGraph == 'Kolej' || currentGraph == 'Arked') {
            // Group items by the selected category
            final categoryGroups = <String, List<String>>{};
            for (var doc in snapshot.docs) {
              String category = doc['faculty'] ?? 'Unknown Category';
              String item = doc['item'] ?? 'Unknown Item';
              if ((currentGraph == 'Faculty' && category.startsWith('Faculty')) ||
                  (currentGraph == 'Kolej' && category.startsWith('Kolej')) ||
                  (currentGraph == 'Arked' && category.startsWith('Arked'))) {
                if (!categoryGroups.containsKey(category)) {
                  categoryGroups[category] = [];
                }
                categoryGroups[category]!.add(item);
              }
            }

            // Prepare data for the table
            final categoryData = categoryGroups.entries.map((entry) {
              String category = entry.key;
              int count = entry.value.length;
              return [category, count.toString(), entry.value.join(', ')];
            }).toList();

            // Add item number to the data
            final numberedCategoryData = categoryData.asMap().entries.map((entry) {
              int index = entry.key + 1; // Start numbering from 1
              List<String> row = entry.value;
              return [index.toString(), ...row];
            }).toList();

            return pw.Column(
              children: [
                pw.Text('Total Items by $currentGraph', style: const pw.TextStyle(fontSize: 24)),
                pw.SizedBox(height: 16),
                pw.TableHelper.fromTextArray(
                  headers: ['No', currentGraph, 'Count', 'Items'],
                  data: numberedCategoryData.map((row) {
                    // Join items with newline character
                    row[3] = row[3].split(', ').join('\n');
                    return row;
                  }).toList(),
                ),
              ],
            );
          } else if (currentGraph == 'Month') {
            // Filter items by the specified month
            DateTime startOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
            DateTime endOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);

            final monthData = snapshot.docs.where((doc) {
              Timestamp createdAtTimestamp = doc['createdAt'];
              DateTime createdAtDate = createdAtTimestamp.toDate();
              return createdAtDate.isAfter(startOfMonth) && createdAtDate.isBefore(endOfMonth);
            }).map((doc) {
              Timestamp createdAtTimestamp = doc['createdAt'];
              DateTime createdAtDate = createdAtTimestamp.toDate();
              String dateKey = DateFormat('yyyy-MM-dd').format(createdAtDate);
              String item = doc['item'] ?? 'Unknown Item';
              return [dateKey, item];
            }).toList();

            // Sort the data by date
            monthData.sort((a, b) => a[0].compareTo(b[0]));

            // Add item number to the data
            final numberedMonthData = monthData.asMap().entries.map((entry) {
              int index = entry.key + 1; // Start numbering from 1
              List<String> row = entry.value;
              return [index.toString(), ...row];
            }).toList();

            return pw.Column(
              children: [
                pw.Text('Total Items - $currentPeriod', style: const pw.TextStyle(fontSize: 24)),
                pw.SizedBox(height: 16),
                pw.TableHelper.fromTextArray(
                  headers: ['No', 'Date', 'Item'],
                  data: numberedMonthData,
                ),
              ],
            );
          } else {
            return pw.Center(
              child: pw.Text('Unknown graph type'),
            );
          }
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/lost_items.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF exported to $path')),
    );

    // Open the PDF file
    await OpenFile.open(path);
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to export PDF')),
    );
  }
}

  Widget _buildSummary() {
    TextStyle summaryTextStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );

    if (currentGraph == 'Faculty') {
      String facultyWithMostItemsLost = facultyLostCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      int mostItemsLost = facultyLostCounts[facultyWithMostItemsLost] ?? 0;
      return Text(
        'Faculty with Most Items Lost: $facultyWithMostItemsLost ($mostItemsLost items)',
        style: summaryTextStyle,
      );
    } else if (currentGraph == 'Kolej') {
      String facultyWithMostItemsLost = facultyLostCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      int mostItemsLost = facultyLostCounts[facultyWithMostItemsLost] ?? 0;
      return Text(
        'Kolej with Most Items Lost: $facultyWithMostItemsLost ($mostItemsLost items)',
        style: summaryTextStyle,
      );
    } else if (currentGraph == 'Arked') {
      String facultyWithMostItemsLost = facultyLostCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      int mostItemsLost = facultyLostCounts[facultyWithMostItemsLost] ?? 0;
      return Text(
        'Arked with Most Items Lost: $facultyWithMostItemsLost ($mostItemsLost items)',
        style: summaryTextStyle,
      );
    } else {
      String dayWithMostItemsLost = timeLostCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      int mostItemsLost = timeLostCounts[dayWithMostItemsLost] ?? 0;
      return Text(
        'Day with Most Items Lost: $dayWithMostItemsLost ($mostItemsLost items)',
        style: summaryTextStyle,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(
        title: "Statistics",
        scaffoldKey: GlobalKey<ScaffoldState>(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF9E6D5), Color(0xFFD5EAE8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _showGraphOptions,
                          child: Text(
                          currentGraph == 'Faculty'
                              ? 'Lost Items - Faculty ↓'
                              : currentGraph == 'Kolej'
                                  ? 'Lost Items - Kolej ↓'
                                  : currentGraph == 'Arked'
                                      ? 'Lost Items - Arked ↓'
                                      : 'Lost Items - Month ↓',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildCurrentPeriodBar(),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 450,
                          child: _buildChart(),
                        ),
                        const SizedBox(height: 24),
                        _buildSummary(), 
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () => _exportToPDF(DateTime.now()), // Pass the current date or the selected date
                              child: const Text('Export to PDF'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}