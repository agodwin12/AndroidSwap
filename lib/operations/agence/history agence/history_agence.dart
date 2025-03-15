import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class HistoryAgence extends StatefulWidget {
  final String uniqueId;

  const HistoryAgence({Key? key, required this.uniqueId}) : super(key: key);

  @override
  State<HistoryAgence> createState() => _HistoryAgenceState();
}

class _HistoryAgenceState extends State<HistoryAgence> {
  List<Map<String, dynamic>> swapHistory = [];
  List<Map<String, dynamic>> filteredHistory = [];
  Map<String, List<Map<String, dynamic>>> dailyGroupedSwaps = {};
  bool isLoading = true;
  String errorMessage = '';
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool isSearchByDate = false;

  @override
  void initState() {
    super.initState();
    fetchSwapHistory();
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = searchController.text;
      applyFilters();
    });
  }

  Future<void> fetchSwapHistory() async {
    final String trimmedId = widget.uniqueId.trim();
    final String apiUrl = "http://10.0.2.2:3010/api/history-agence/$trimmedId";

    print("🔍 [DEBUG] API Request URL: $apiUrl");

    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final response = await http.get(Uri.parse(apiUrl)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception("Server timeout: API did not respond.");
        },
      );

      print("🔍 [DEBUG] API Response Status: ${response.statusCode}");
      print("🔍 [DEBUG] API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          swapHistory = List<Map<String, dynamic>>.from(data["swaps"]);
          processSwapData();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load swap history. Server responded with ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = "Error fetching swap history: $error";
        isLoading = false;
      });
    }
  }

  void processSwapData() {
    // Group by date
    dailyGroupedSwaps = {};

    for (var swap in swapHistory) {
      DateTime swapDate = DateTime.parse(swap['swap_date']);
      String dateKey = DateFormat('yyyy-MM-dd').format(swapDate);

      if (!dailyGroupedSwaps.containsKey(dateKey)) {
        dailyGroupedSwaps[dateKey] = [];
      }

      dailyGroupedSwaps[dateKey]!.add(swap);
    }

    applyFilters();
  }

  void applyFilters() {
    // Start with all data
    List<Map<String, dynamic>> result = List.from(swapHistory);

    // Apply date range filter
    if (selectedStartDate != null || selectedEndDate != null) {
      result = result.where((swap) {
        DateTime swapDate = DateTime.parse(swap['swap_date']);
        if (selectedStartDate != null && selectedEndDate != null) {
          return swapDate.isAfter(selectedStartDate!) &&
              swapDate.isBefore(selectedEndDate!.add(const Duration(days: 1)));
        } else if (selectedStartDate != null) {
          return swapDate.isAfter(selectedStartDate!);
        } else {
          return swapDate.isBefore(selectedEndDate!.add(const Duration(days: 1)));
        }
      }).toList();
    }

    // Apply search query filter if not empty
    if (searchQuery.isNotEmpty) {
      if (isSearchByDate) {
        // Search by date
        try {
          // Try different date formats
          DateTime? searchDate;
          List<String> dateFormats = [
            'yyyy-MM-dd', 'dd/MM/yyyy', 'MM/dd/yyyy',
            'dd-MM-yyyy', 'MM-dd-yyyy',
            'dd MMM yyyy', 'MMM dd yyyy'
          ];

          for (var format in dateFormats) {
            try {
              searchDate = DateFormat(format).parse(searchQuery);
              break; // If successful, stop trying other formats
            } catch (e) {
              // Continue trying other formats
            }
          }

          if (searchDate != null) {
            String formattedSearchDate = DateFormat('yyyy-MM-dd').format(searchDate);
            result = result.where((swap) {
              String swapDateStr = DateFormat('yyyy-MM-dd').format(DateTime.parse(swap['swap_date']));
              return swapDateStr == formattedSearchDate;
            }).toList();
          } else {
            // If no valid date format found, try partial date matching
            result = result.where((swap) {
              DateTime swapDate = DateTime.parse(swap['swap_date']);
              String formattedSwapDate = DateFormat('yyyy-MM-dd').format(swapDate);
              String dayMonth = DateFormat('dd/MM').format(swapDate);
              String monthYear = DateFormat('MM/yyyy').format(swapDate);

              return formattedSwapDate.contains(searchQuery) ||
                  dayMonth.contains(searchQuery) ||
                  monthYear.contains(searchQuery) ||
                  DateFormat('MMMM').format(swapDate).toLowerCase().contains(searchQuery.toLowerCase()) ||
                  DateFormat('EEEE').format(swapDate).toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();
          }
        } catch (e) {
          print("Error parsing date: $e");
          // If date parsing fails completely, return empty results
          result = [];
        }
      } else {
        // Search in other fields
        result = result.where((swap) {
          // Search in battery macId
          final batteryInMac = swap['battery_in_mac'].toString().toLowerCase();
          final batteryOutMac = swap['battery_out_mac'].toString().toLowerCase();

          // Search in name and phone
          final name = "${swap['nom']} ${swap['prenom']}".toLowerCase();
          final phone = swap['phone'].toString().toLowerCase();

          return batteryInMac.contains(searchQuery.toLowerCase()) ||
              batteryOutMac.contains(searchQuery.toLowerCase()) ||
              name.contains(searchQuery.toLowerCase()) ||
              phone.contains(searchQuery.toLowerCase());
        }).toList();
      }
    }

    setState(() {
      filteredHistory = result;
      // Recalculate daily groupings for filtered data
      updateDailyGroupedSwaps();
    });
  }

  void updateDailyGroupedSwaps() {
    dailyGroupedSwaps = {};

    for (var swap in filteredHistory) {
      DateTime swapDate = DateTime.parse(swap['swap_date']);
      String dateKey = DateFormat('yyyy-MM-dd').format(swapDate);

      if (!dailyGroupedSwaps.containsKey(dateKey)) {
        dailyGroupedSwaps[dateKey] = [];
      }

      dailyGroupedSwaps[dateKey]!.add(swap);
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedStartDate != null && selectedEndDate != null
          ? DateTimeRange(start: selectedStartDate!, end: selectedEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedStartDate = picked.start;
        selectedEndDate = picked.end;
      });
      applyFilters();
    }
  }

  Future<void> _selectSingleDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Format as yyyy-MM-dd
      String formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      searchController.text = formattedDate;
      setState(() {
        isSearchByDate = true;
      });
      applyFilters();
    }
  }

  void clearDateFilter() {
    setState(() {
      selectedStartDate = null;
      selectedEndDate = null;
    });
    applyFilters();
  }

  void toggleSearchMode() {
    setState(() {
      isSearchByDate = !isSearchByDate;
      searchController.clear();
    });
  }

  String _formatDate(String dateStr) {
    final DateTime date = DateTime.parse(dateStr);
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  String _formatDayHeader(String dateKey) {
    final DateTime date = DateTime.parse(dateKey);
    return DateFormat('EEEE, MMMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: fetchSwapHistory,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.black,
              actions: [
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDateRange(context),
                ),
                if (selectedStartDate != null || selectedEndDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: clearDateFilter,
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Swap History',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black,
                        Colors.grey[900]!,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search bar with toggle button and calendar icon
                    Row(
                      children: [
                        Expanded(
                          child: Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: isSearchByDate
                                      ? 'Search by date (e.g., yyyy-mm-dd)'
                                      : 'Search by battery ID, name or phone...',
                                  prefixIcon: Icon(
                                    isSearchByDate ? Icons.date_range : Icons.search,
                                  ),
                                  suffixIcon: searchQuery.isNotEmpty
                                      ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      searchController.clear();
                                    },
                                  )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              if (isSearchByDate && searchQuery.isEmpty)
                                Positioned(
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.calendar_today),
                                    onPressed: () => _selectSingleDate(context),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Toggle button
                        InkWell(
                          onTap: toggleSearchMode,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isSearchByDate ? Icons.search : Icons.date_range,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (selectedStartDate != null || selectedEndDate != null)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[200],
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filtered: ${DateFormat('MMM dd, yyyy').format(selectedStartDate ?? DateTime.now())} - '
                              '${DateFormat('MMM dd, yyyy').format(selectedEndDate ?? DateTime.now())}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Text(
                        '${filteredHistory.length} results',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(
            color: Colors.black,
          ),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: GoogleFonts.poppins(
                  color: Colors.red.shade300,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchSwapHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                searchQuery.isNotEmpty
                    ? isSearchByDate
                    ? 'No swaps found on this date'
                    : 'No swaps found matching "$searchQuery"'
                    : selectedStartDate != null || selectedEndDate != null
                    ? 'No swaps found for selected dates'
                    : 'No swap history found',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    List<String> sortedDays = dailyGroupedSwaps.keys.toList()
      ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: sortedDays.map((dateKey) {
          final swapsForDay = dailyGroupedSwaps[dateKey]!;
          final dayTotal = swapsForDay.fold<double>(
              0,
                  (sum, swap) => sum + (double.tryParse(swap['swap_price'].toString()) ?? 0)
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDayHeader(dateKey, swapsForDay.length, dayTotal),
              ...swapsForDay.map((swap) => _buildSwapCard(swap)).toList(),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayHeader(String dateKey, int swapCount, double dayTotal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDayHeader(dateKey),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$swapCount swaps',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${dayTotal.toStringAsFixed(0)} FCFA',
                style: GoogleFonts.poppins(
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'daily total',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwapCard(Map<String, dynamic> swap) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${swap['nom']} ${swap['prenom']}",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(swap['swap_date']),
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${swap['swap_price']} FCFA',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  swap['phone'],
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildBatteryInfo(
              'Outgoing Battery',
              swap['battery_out_mac'],
              double.tryParse(swap['battery_out_soc']?.toString() ?? '0') ?? 0.0,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildBatteryInfo(
              'Incoming Battery',
              swap['battery_in_mac'],
              swap['battery_in_soc'] != null && swap['battery_in_soc'] != ''
                  ? double.tryParse(swap['battery_in_soc'].toString()) ?? 0.0
                  : 0.0,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryInfo(String label, String macId, double soc, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    macId,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Stack(
                    children: [
                      Container(
                        height: 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: soc / 100,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${soc.toStringAsFixed(1)}%',
                style: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }
}