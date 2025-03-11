import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:animations/animations.dart';

class DistributeurHistoryScreen extends StatefulWidget {
  final String distributeurUniqueId;

  const DistributeurHistoryScreen(
      {Key? key, required this.distributeurUniqueId})
      : super(key: key);

  @override
  _DistributeurHistoryScreenState createState() =>
      _DistributeurHistoryScreenState();
}

class _DistributeurHistoryScreenState extends State<DistributeurHistoryScreen> {
  List<Map<String, dynamic>> _originalHistory = [];
  List<Map<String, dynamic>> _filteredHistory = [];
  bool _isLoading = false;
  String _errorMessage = "";

  // Date filtering variables
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _fetchDistributeurHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final url =
        "http://57.128.178.119:3010/api/historique/distributeur/${widget.distributeurUniqueId}";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["success"] == true && data["history"] is List) {
          setState(() {
            _originalHistory = List<Map<String, dynamic>>.from(data["history"]);
            _filteredHistory = List<Map<String, dynamic>>.from(data["history"]);
            _isLoading = false;
          });
        } else {
          throw Exception("Invalid response format from server.");
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = "No history available.";
          _isLoading = false;
        });
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to fetch history. Please try again.";
      });
    }
  }

  void _filterHistoryByDate() {
    if (_startDate == null && _endDate == null) {
      setState(() {
        _filteredHistory = _originalHistory;
      });
      return;
    }

    setState(() {
      _filteredHistory = _originalHistory.where((record) {
        final recordDate = DateTime.parse(record['date_time']);

        if (_startDate != null && _endDate != null) {
          return recordDate.isAfter(_startDate!) &&
              recordDate.isBefore(_endDate!.add(const Duration(days: 1)));
        }

        if (_startDate != null) {
          return recordDate.isAfter(_startDate!);
        }

        if (_endDate != null) {
          return recordDate.isBefore(_endDate!.add(const Duration(days: 1)));
        }

        return true;
      }).toList();
    });
  }

  void _showDateRangePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Date Range'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(_startDate == null
                    ? 'Select Start Date'
                    : 'Start: ${DateFormat('dd MMM yyyy').format(_startDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _startDate = pickedDate;
                    });
                  }
                },
              ),
              ListTile(
                title: Text(_endDate == null
                    ? 'Select End Date'
                    : 'End: ${DateFormat('dd MMM yyyy').format(_endDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _endDate = pickedDate;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                  _filteredHistory = _originalHistory;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () {
                _filterHistoryByDate();
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchDistributeurHistory();
  }

  String _formatDate(String dateTime) {
    final DateTime parsedDate = DateTime.parse(dateTime);
    return DateFormat('dd MMM yyyy, hh:mm a').format(parsedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Battery Swap History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple[500],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showDateRangePickerDialog,
            tooltip: 'Filter by Date',
          ),
        ],
      ),
      body: _buildBody(),
      backgroundColor: Colors.grey[100],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.deepPurple,
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade300,
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchDistributeurHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade500,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Retry",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              color: Colors.grey.shade400,
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              "No swap history yet",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_startDate != null || _endDate != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtered: ${_startDate != null ? DateFormat('dd MMM yyyy').format(_startDate!) : 'Start'} - '
                  '${_endDate != null ? DateFormat('dd MMM yyyy').format(_endDate!) : 'End'}',
                  style: TextStyle(
                    color: Colors.deepPurple.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                      _filteredHistory = _originalHistory;
                    });
                  },
                  color: Colors.red.shade300,
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            itemCount: _filteredHistory.length,
            itemBuilder: (context, index) {
              final record = _filteredHistory[index];
              return _buildHistoryCard(record);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> record) {
    return OpenContainer(
      transitionType: ContainerTransitionType.fadeThrough,
      closedBuilder: (BuildContext context, VoidCallback openContainer) => Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            "${record['nom_agence']} (${record['ville']})",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                _formatDate(record['date_time']),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildBadge(
                    Icons.battery_charging_full,
                    Colors.green,
                    record['bat_entrante']?.length ?? 0,
                    "Incoming",
                  ),
                  const SizedBox(width: 16),
                  _buildBadge(
                    Icons.battery_alert,
                    Colors.red,
                    record['bat_sortante']?.length ?? 0,
                    "Outgoing",
                  ),
                ],
              ),
            ],
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: Colors.deepPurple.shade500,
            size: 30,
          ),
          onTap: openContainer,
        ),
      ),
      openBuilder: (BuildContext context, VoidCallback _) =>
          _HistoryDetailScreen(record: record),
    );
  }

  Widget _buildBadge(IconData icon, Color color, int count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            "$count $label",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> record;

  const _HistoryDetailScreen({Key? key, required this.record})
      : super(key: key);

  String _formatDate(String dateTime) {
    final DateTime parsedDate = DateTime.parse(dateTime);
    return DateFormat('dd MMM yyyy, hh:mm a').format(parsedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Swap Details - ${record['nom_agence']}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple.shade500,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 16),
          _buildBatteriesSection(
            title: "Incoming Batteries",
            batteries: record['bat_entrante'] ?? [],
            color: Colors.green,
            icon: Icons.battery_charging_full,
          ),
          const SizedBox(height: 16),
          _buildBatteriesSection(
            title: "Outgoing Batteries",
            batteries: record['bat_sortante'] ?? [],
            color: Colors.red,
            icon: Icons.battery_alert,
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record['nom_proprietaire'],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${record['nom_agence']} - ${record['ville']}",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.deepPurple.shade500),
                const SizedBox(width: 8),
                Text(
                  _formatDate(record['date_time']),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Swap Type: ${record['type_swap']}",
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteriesSection({
    required String title,
    required List batteries,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              "$title (${batteries.length})",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        children: batteries.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "No batteries $title".toLowerCase(),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              ]
            : batteries.map<Widget>((battery) {
                return ListTile(
                  leading: Icon(Icons.battery_full, color: color),
                  title: Text(battery['mac_id']),

                );
              }).toList(),
      ),
    );
  }
}
