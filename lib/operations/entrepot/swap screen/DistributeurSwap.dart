import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:swap/operations/agence/dashboard/widget/colors.dart';

class DistributeurSwapEntrepot extends StatefulWidget {
  final String selectedSwapType;
  final String uniqueId;
  final Map<String, dynamic> loggedInUser;
  final String distributeurId;
  final String idEntrepot;

  const DistributeurSwapEntrepot({
    Key? key,
    required this.selectedSwapType,
    required this.uniqueId,
    required this.loggedInUser,
    required this.distributeurId,
    required this.idEntrepot,
  }) : super(key: key);

  @override
  _DistributeurSwapEntrepotState createState() => _DistributeurSwapEntrepotState();
}

class _DistributeurSwapEntrepotState extends State<DistributeurSwapEntrepot> {
  List<String> allOutgoingBatteries = [];
  List<String> selectedOutgoingBatteries = [];
  List<String> allIncomingBatteries = [];
  List<String> selectedIncomingBatteries = [];

  String outgoingSearchQuery = '';
  String incomingSearchQuery = '';
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    print("🔍 [DEBUG] DistributeurSwapEntrepot Initialized with:");
    print(" - Selected Swap Type: ${widget.selectedSwapType}");
    print(" - Unique ID: ${widget.uniqueId}");
    print(" - Distributeur ID: ${widget.distributeurId}");
    print(" - Entrepôt ID: ${widget.idEntrepot}");

    fetchBatteriesEntrepot();
    fetchBatteriesDistributeur();
  }

  Future<void> fetchBatteriesEntrepot() async {
    try {
      print("🌍 [API CALL] Fetching batteries for entrepôt: ${widget.idEntrepot}");
      final response = await http.get(
        Uri.parse("http://57.128.178.119:3010/api/batteries/entrepot/${widget.idEntrepot}"),
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        setState(() {
          allOutgoingBatteries = (decodedData["batteries"] as List)
              .map((battery) => battery["mac_id"].toString())
              .toList();
        });
      } else {
        print("⚠️ [WARNING] Failed to fetch entrepôt batteries.");
      }
    } catch (error) {
      print("❌ [ERROR] Fetching batteries failed: $error");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchBatteriesDistributeur() async {
    try {
      print("🌍 [API CALL] Fetching batteries for Distributeur ID: ${widget.distributeurId}");

      final url = Uri.parse("http://57.128.178.119:3010/api/batteries/distributeur/${widget.distributeurId}");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);

        if (decodedData["success"] == true && decodedData["batteries"] != null) {
          setState(() {
            allIncomingBatteries = (decodedData["batteries"] as List)
                .map((battery) => battery["mac_id"].toString())
                .toList();
          });
        } else {
          print("⚠️ [INFO] No batteries found.");
          setState(() {
            allIncomingBatteries = [];
          });
        }
      } else {
        print("❌ [ERROR] API Response: ${response.statusCode} - ${response.body}");
        setState(() {
          allIncomingBatteries = [];
        });
      }
    } catch (error) {
      print("❌ [ERROR] Fetching Distributeur batteries failed: $error");
      setState(() {
        allIncomingBatteries = [];
      });
    }
  }


  Future<void> performSwap() async {
    try {
      String? uniqueId = widget.loggedInUser["unique_id"];

      if (uniqueId == null || uniqueId.isEmpty) {
        throw Exception("User Unique ID is missing!");
      }

      var payload = {
        "id_entrepot": widget.idEntrepot,
        "id_distributeur": widget.distributeurId,
        "id_user_entrepot": uniqueId,
        "bat_sortante": json.encode(selectedOutgoingBatteries),
        "bat_entrante": json.encode(selectedIncomingBatteries),
        "type_swap": selectedOutgoingBatteries.isNotEmpty ? "livraison" : "retour",
      };

      print("🚀 [API CALL] Sending swap request: ${json.encode(payload)}");

      var response = await http.post(
        Uri.parse("http://57.128.178.119:3010/api/swap/battery-entrepot"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );

      print("📡 [API RESPONSE] Status Code: ${response.statusCode}");
      print("📡 [API RESPONSE] Body: ${response.body}");

      if (response.statusCode == 200) {
        print("✅ [SUCCESS] Swap completed!");
      } else {
        throw Exception("❌ [ERROR] Swap failed: ${response.body}");
      }
    } catch (error) {
      print("🔥 [ERROR] Swap failed: $error");
      throw error;
    }
  }


  Future<void> _showConfirmationDialog() async {
    final DateTime now = DateTime.now();
    final String formattedDate = "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Confirm Battery Swap',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                SizedBox(height: 20),
                _buildInfoRow('Date', formattedDate),
                _buildInfoRow('User ID', widget.loggedInUser["unique_id"] ?? 'N/A'),
                _buildInfoRow('Distributeur ID', widget.distributeurId),
                Divider(height: 30),
                _buildBatteryCount(
                  'Outgoing Batteries',
                  selectedOutgoingBatteries.length,
                  Colors.orange,
                ),
                SizedBox(height: 10),
                _buildBatteryCount(
                  'Incoming Batteries',
                  selectedIncomingBatteries.length,
                  Colors.green,
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFDBDB35),
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Validate',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          await performSwap();
          _showResultDialog(true);
        } catch (error) {
          _showResultDialog(false);
        }
      }
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D2D2D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryCount(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showResultDialog(bool success) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  success ? 'assets/Success.json' : 'assets/error.json',
                  width: 200,
                  height: 200,
                  repeat: false,
                ),
                SizedBox(height: 20),
                Text(
                  success ? 'Swap Successful!' : 'Swap Failed',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: success ? Colors.green : Colors.red,
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (success) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: success ? Color(0xFFDBDB35) : Colors.grey,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(String hint, Function(String) onSearch) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        decoration: InputDecoration(
          labelText: hint,
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: onSearch,
      ),
    );
  }

  Widget _buildBatteryList(List<String> allBatteries, List<String> selectedBatteries, String searchQuery) {
    return Expanded(
      child: ListView(
        children: allBatteries
            .where((battery) => battery.toLowerCase().contains(searchQuery.toLowerCase()))
            .map((battery) => CheckboxListTile(
          title: Text(battery),
          value: selectedBatteries.contains(battery),
          onChanged: (isSelected) {
            setState(() {
              if (isSelected == true) {
                selectedBatteries.add(battery);
              } else {
                selectedBatteries.remove(battery);
              }
            });
          },
        ))
            .toList(),
      ),
    );
  }

  Widget _buildSelectedBatteriesBlock() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(" Selected Batteries",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
    ),
    SizedBox(height: 10),
    Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text("🏭 From Entrepôt",
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
    ),
    SizedBox(height: 5),
    ...selectedOutgoingBatteries.isNotEmpty
    ? selectedOutgoingBatteries.map((battery) =>
    Text("🔋 $battery",
    style: TextStyle(fontSize: 14)
    )).toList()
        : [Text("No Batteries Selected",
    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)
    )],
    ],
    ),
    ),
    SizedBox(width: 20),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text("🏪 From Distributeur",
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
    ),
    SizedBox(height: 5),
    ...selectedIncomingBatteries.isNotEmpty
    ? selectedIncomingBatteries.map((battery) =>
    Text("🔋 $battery",style: TextStyle(fontSize: 14)
    )).toList()
        : [Text("No Batteries Selected",
        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)
    )],
    ],
    ),
    ),
    ],
    ),
        ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Swap With Distributeur",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primaryYellow,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "🔋 Outgoing Batteries from Entrepôt",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            _buildSearchBar("Search Entrepôt Batteries", (query) {
              setState(() => outgoingSearchQuery = query);
            }),
            _buildBatteryList(
              allOutgoingBatteries,
              selectedOutgoingBatteries,
              outgoingSearchQuery,
            ),
            SizedBox(height: 20),

            Text(
              "🔋 Incoming Batteries from Distributeur",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            _buildSearchBar("Search Distributeur Batteries", (query) {
              setState(() => incomingSearchQuery = query);
            }),
            _buildBatteryList(
              allIncomingBatteries,
              selectedIncomingBatteries,
              incomingSearchQuery,
            ),
            SizedBox(height: 20),

            _buildSelectedBatteriesBlock(),

            SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedOutgoingBatteries.isEmpty && selectedIncomingBatteries.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Please select at least one battery to swap.",
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    );
                    return;
                  }
                  _showConfirmationDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFDBDB35),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Process Swap",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}