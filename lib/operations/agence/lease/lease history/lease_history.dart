import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class LeaseHistoryScreen extends StatefulWidget {
  final String uniqueId;

  const LeaseHistoryScreen({Key? key, required this.uniqueId}) : super(key: key);

  @override
  _LeaseHistoryScreenState createState() => _LeaseHistoryScreenState();
}

class _LeaseHistoryScreenState extends State<LeaseHistoryScreen> {
  List<dynamic> leasePayments = [];
  List<dynamic> filteredPayments = [];
  bool isLoading = true;
  String _selectedFilter = 'All';
  DateTime? _selectedDate;

  final List<String> _filterOptions = [
    'All',
    'Yesterday',
    'This Week',
    'This Month',
    'Custom Date'
  ];

  @override
  void initState() {
    super.initState();
    _fetchLeasePayments();
  }

  Future<void> _fetchLeasePayments() async {
    final String apiUrl = "http://10.0.2.2:3010/api/payments/lease/history?uniqueId=${widget.uniqueId}";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          leasePayments = responseData["lease_payments"] ?? [];
          filteredPayments = leasePayments;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load lease history");
      }
    } catch (error) {
      print("❌ ERROR fetching lease payments: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFFDCDB32),
              onPrimary: Colors.black,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedFilter = 'Custom Date';

        // Filter payments for the selected date
        filteredPayments = leasePayments.where((payment) {
          final paymentDate = DateTime.parse(payment['created_at']);
          return paymentDate.year == picked.year &&
              paymentDate.month == picked.month &&
              paymentDate.day == picked.day;
        }).toList();
      });
    }
  }

  void _filterPayments(String filter) {
    setState(() {
      _selectedFilter = filter;
      final now = DateTime.now();

      if (filter == 'Custom Date') {
        _selectDate(context);
        return;
      }

      switch (filter) {
        case 'All':
          filteredPayments = leasePayments;
          break;
        case 'Yesterday':
          final yesterday = now.subtract(Duration(days: 1));
          filteredPayments = leasePayments.where((payment) {
            final paymentDate = DateTime.parse(payment['created_at']);
            return paymentDate.year == yesterday.year &&
                paymentDate.month == yesterday.month &&
                paymentDate.day == yesterday.day;
          }).toList();
          break;
        case 'This Week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          filteredPayments = leasePayments.where((payment) {
            final paymentDate = DateTime.parse(payment['created_at']);
            return paymentDate.isAfter(weekStart.subtract(Duration(days: 1))) &&
                paymentDate.isBefore(now.add(Duration(days: 1)));
          }).toList();
          break;
        case 'This Month':
          filteredPayments = leasePayments.where((payment) {
            final paymentDate = DateTime.parse(payment['created_at']);
            return paymentDate.year == now.year && paymentDate.month == now.month;
          }).toList();
          break;
      }
    });
  }

  double _calculateTotalCollected() {
    return filteredPayments.fold(0.0, (total, payment) =>
    total + (double.tryParse(payment['total_lease'].toString()) ?? 0.0));
  }

  // New method to calculate daily totals
  Map<String, double> _calculateDailyTotals() {
    Map<String, double> dailyTotals = {};

    for (var payment in filteredPayments) {
      final createdAt = payment['created_at'] ?? "Unknown Date";
      final formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(createdAt));
      final amount = double.tryParse(payment['total_lease'].toString()) ?? 0.0;

      if (dailyTotals.containsKey(formattedDate)) {
        dailyTotals[formattedDate] = dailyTotals[formattedDate]! + amount;
      } else {
        dailyTotals[formattedDate] = amount;
      }
    }

    return dailyTotals;
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: _filterOptions.map((filter) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(filter,
                style: GoogleFonts.poppins(
                  color: _selectedFilter == filter ? Colors.white : Colors.black,
                ),
              ),
              selected: _selectedFilter == filter,
              onSelected: (bool selected) {
                if (selected) {
                  _filterPayments(filter);
                }
              },
              selectedColor: Color(0xFFDCDB32),
              backgroundColor: Colors.grey[200],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get daily totals for the filtered payments
    final dailyTotals = _calculateDailyTotals();

    String filterDisplayText = _selectedFilter;
    if (_selectedFilter == 'Custom Date' && _selectedDate != null) {
      filterDisplayText = DateFormat('MMM dd, yyyy').format(_selectedDate!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            "Lease History",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white
            )
        ),
        backgroundColor: Color(0xFFDCDB32),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Collected Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            color: Color(0xFFDCDB32).withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedFilter == 'All'
                      ? "Total Collected"
                      : "$filterDisplayText Collected",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "\$${_calculateTotalCollected().toStringAsFixed(2)}",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          _buildFilterChips(),

          // Daily Totals Section (visible when filtered)
          if (_selectedFilter != 'All' && dailyTotals.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              color: Color(0xFFDCDB32).withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Daily Breakdown",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 12),
                  ...dailyTotals.entries.map((entry) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "\$${entry.value.toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),

          // Lease History List
          Expanded(
            child: isLoading
                ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFFDCDB32),
              ),
            )
                : filteredPayments.isEmpty
                ? Center(
              child: Text(
                "No lease history found",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 12),
              itemCount: filteredPayments.length,
              itemBuilder: (context, index) {
                final lease = filteredPayments[index];

                final user = lease['user'] ?? {};
                final userName = "${user['nom'] ?? 'N/A'} ${user['prenom'] ?? ''}".trim();
                final userPhone = user['phone'] ?? 'N/A';
                final createdAt = lease['created_at'] ?? "Unknown Date";
                final formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(createdAt));

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with date and status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFDCDB32).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.receipt_long_outlined,
                                    color: Color(0xFFDCDB32),
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  formattedDate,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: lease['statut'] == 'Paid'
                                    ? Colors.green[50]
                                    : Colors.orange[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: lease['statut'] == 'paid'
                                      ? Colors.green[400]!
                                      : Colors.orange[400]!,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                "${lease['statut']}",
                                style: GoogleFonts.poppins(
                                  color: lease['statut'] == 'paid'
                                      ? Colors.green[800]
                                      : Colors.orange[800],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // User Information
                        Text(
                          "User: $userName",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),

                        SizedBox(height: 12),

                        // Moto Information
                        Text(
                          "Moto: ${lease['moto']['moto_unique_id']}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        SizedBox(height: 8),

                        // VIN Information
                        Text(
                          "VIN: ${lease['moto']['vin']}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),

                        SizedBox(height: 8),

                        // Phone Information
                        Text(
                          "Phone: $userPhone",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 16),

                        // Total amount with prominent styling
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Color(0xFFDCDB32).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Total: \$${lease['total_lease']}",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.green,
                            ),
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
    );
  }
}