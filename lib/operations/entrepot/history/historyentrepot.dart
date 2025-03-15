import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSwapHistory extends StatefulWidget {
  const UserSwapHistory({Key? key}) : super(key: key);

  @override
  State<UserSwapHistory> createState() => _UserSwapHistoryState();
}

class _UserSwapHistoryState extends State<UserSwapHistory> {
  List<Map<String, dynamic>> swapHistory = [];
  List<Map<String, dynamic>> filteredHistory = [];
  bool isLoading = true;
  String errorMessage = '';
  String? userUniqueId;
  Map<int, bool> expandedItems = {};
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchHistory();
  }

  Future<void> _loadUserIdAndFetchHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uniqueId = prefs.getString("unique_id");

    if (uniqueId == null || uniqueId.isEmpty) {
      setState(() {
        errorMessage = "No Unique ID found. Please log in again.";
        isLoading = false;
      });
      return;
    }

    setState(() {
      userUniqueId = uniqueId;
    });

    await fetchSwapHistory();
  }

  Future<void> fetchSwapHistory() async {
    if (userUniqueId == null || userUniqueId!.isEmpty) {
      setState(() {
        errorMessage = "No Unique ID found. Please log in again.";
        isLoading = false;
      });
      return;
    }

    final String apiUrl = "http://10.0.2.2:3010/api/historique-entrepot/$userUniqueId";

    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception("Server timeout");
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          swapHistory = List<Map<String, dynamic>>.from(data["historique"]);
          filteredHistory = swapHistory;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load swap history.";
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = "Error: $error";
        isLoading = false;
      });
    }
  }

  void filterHistory() {
    if (selectedStartDate == null && selectedEndDate == null) {
      setState(() {
        filteredHistory = swapHistory;
      });
      return;
    }

    setState(() {
      filteredHistory = swapHistory.where((swap) {
        DateTime swapDate = DateTime.parse(swap['created_at']);
        if (selectedStartDate != null && selectedEndDate != null) {
          return swapDate.isAfter(selectedStartDate!) &&
              swapDate.isBefore(selectedEndDate!.add(const Duration(days: 1)));
        } else if (selectedStartDate != null) {
          return swapDate.isAfter(selectedStartDate!);
        } else {
          return swapDate.isBefore(selectedEndDate!.add(const Duration(days: 1)));
        }
      }).toList();
    });
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
              primary: Colors.black87,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
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
      filterHistory();
    }
  }

  void clearDateFilter() {
    setState(() {
      selectedStartDate = null;
      selectedEndDate = null;
      filteredHistory = swapHistory;
    });
  }

  List<String> _decodeBatteryList(String? batteryData) {
    if (batteryData == null || batteryData.isEmpty) return [];
    try {
      return List<String>.from(jsonDecode(batteryData));
    } catch (e) {
      return [];
    }
  }

  void _toggleExpansion(int index) {
    setState(() {
      expandedItems[index] = !(expandedItems[index] ?? false);
    });
  }

  String _formatDateTime(String dateTime) {
    final DateTime dt = DateTime.parse(dateTime);
    return DateFormat('MMM d, y • HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Swap History",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.black87),
            onPressed: () => _selectDateRange(context),
          ),
          if (selectedStartDate != null || selectedEndDate != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.black87),
              onPressed: clearDateFilter,
            ),
        ],
      ),
      body: Column(
        children: [
          if (selectedStartDate != null || selectedEndDate != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
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
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                ? _buildErrorState()
                : _buildSwapList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: GoogleFonts.poppins(
                color: Colors.red[300],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwapList() {
    if (filteredHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              selectedStartDate != null || selectedEndDate != null
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredHistory.length,
      itemBuilder: (context, index) {
        return _buildSwapCard(filteredHistory[index], index);
      },
    );
  }

  Widget _buildSwapCard(Map<String, dynamic> swap, int index) {
    final bool isLivraison = swap['type_swap'] == 'livraison';
    final List<String> batteriesSortantes = _decodeBatteryList(swap['bat_sortante']);
    final List<String> batteriesEntrantes = _decodeBatteryList(swap['bat_entrante']);
    final String nomAgence = swap['agence']?['nom_agence'] ?? "Unknown";
    final String villeAgence = swap['agence']?['ville'] ?? "Unknown";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      swap['type_swap'].toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isLivraison ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDateTime(swap['created_at']),
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "📍 $nomAgence, $villeAgence",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildBatteryCount(
                      isOutgoing: true,
                      count: batteriesSortantes.length,
                      onTap: () => _toggleExpansion(index),
                      isExpanded: expandedItems[index] ?? false,
                    ),
                    const SizedBox(width: 12),
                    _buildBatteryCount(
                      isOutgoing: false,
                      count: batteriesEntrantes.length,
                      onTap: () => _toggleExpansion(index),
                      isExpanded: expandedItems[index] ?? false,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (expandedItems[index] == true) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (batteriesSortantes.isNotEmpty) ...[
                    Text(
                      "Outgoing Batteries:",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildBatteryList(batteriesSortantes),
                    const SizedBox(height: 12),
                  ],
                  if (batteriesEntrantes.isNotEmpty) ...[
                    Text(
                      "Incoming Batteries:",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildBatteryList(batteriesEntrantes),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBatteryCount({
    required bool isOutgoing,
    required int count,
    required VoidCallback onTap,
    required bool isExpanded,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOutgoing ? Colors.red[50] : Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOutgoing ? Colors.red[200]! : Colors.green[200]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOutgoing ? Icons.upload : Icons.download,
              size: 16,
              color: isOutgoing ? Colors.red[700] : Colors.green[700],
            ),
            const SizedBox(width: 8),
            Text(
              "$count ${isOutgoing ? 'Out' : 'In'}",
              style: GoogleFonts.poppins(
                color: isOutgoing ? Colors.red[700] : Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 16,
              color: isOutgoing ? Colors.red[700] : Colors.green[700],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryList(List<String> batteries) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: batteries.map((battery) => _buildBatteryChip(battery)).toList(),
    );
  }

  Widget _buildBatteryChip(String battery) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        battery,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  // Helper method to handle pull-to-refresh
  Future<void> _handleRefresh() async {
    await fetchSwapHistory();
    // Re-apply filters if they exist
    if (selectedStartDate != null || selectedEndDate != null) {
      filterHistory();
    }
  }

  // Helper method to export history (if needed)
  void _exportHistory() {
    // Implement export functionality if needed
    // This could export to CSV or PDF
  }
}