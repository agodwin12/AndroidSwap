import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swap/operations/agence/dashboard/widget/colors.dart';
import '../main swap/swap.dart';

class DistributorSwapType extends StatefulWidget {
  final Map<String, dynamic> loggedInUser;

  const DistributorSwapType({Key? key, required this.loggedInUser}) : super(key: key);

  @override
  _DistributorSwapTypeState createState() => _DistributorSwapTypeState();
}

class _DistributorSwapTypeState extends State<DistributorSwapType> {
  List<Map<String, dynamic>> agencyList = [];
  List<Map<String, dynamic>> filteredList = [];
  Map<String, dynamic>? selectedAgency;
  TextEditingController searchController = TextEditingController();
  bool showNextButton = false;
  bool isLoading = false;
  bool isButtonLoading = false;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    _fetchAgencies();
  }

  /// **Fetch Agencies from API**
  Future<void> _fetchAgencies() async {
    const String apiUrl = "http://10.0.2.2:3010/api/swaps/agencies";

    setState(() {
      isLoading = true;
    });

    try {
      print("🌍 [API CALL] Fetching agencies from: $apiUrl");
      final response = await http.get(Uri.parse(apiUrl), headers: {'Content-Type': 'application/json'});

      print("📩 [DEBUG] Response Status: ${response.statusCode}");
      print("🔍 [DEBUG] Raw Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(response.body);
        setState(() {
          agencyList = decodedData.map((e) => Map<String, dynamic>.from(e)).toList();
          filteredList = List.from(agencyList);
          isLoading = false;
        });
      } else {
        print("❌ [ERROR] Failed to fetch agencies");
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print("❌ [ERROR] API Error: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  /// **Handles Agency Selection**
  void _selectAgency(Map<String, dynamic> agency, int index) {
    setState(() {
      selectedAgency = agency;
      selectedIndex = index;
      showNextButton = true;
      searchController.text = agency["nom_agence"] ?? "Unknown";
    });
  }

  /// **Filters Agencies Based on Search Query**
  void _filterAgencies(String query) {
    setState(() {
      filteredList = agencyList.where((agency) {
        final String name = agency["nom_agence"] ?? "";
        final String id = agency["agence_unique_id"] ?? "";

        return name.toLowerCase().contains(query.toLowerCase()) ||
            id.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  /// **Clears Search Field**
  void _clearSearch() {
    setState(() {
      searchController.clear();
      filteredList = List.from(agencyList);
    });
  }

  /// **Handles "Next" Button Press**
  void _onNextPressed() async {
    if (selectedAgency == null) {
      print("❌ [ERROR] No agency selected!");
      return;
    }

    setState(() {
      isButtonLoading = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // ✅ Store Distributeur ID
      String distributeurId = widget.loggedInUser["unique_id"] ?? "Unknown";
      await prefs.setString('distributeur_id', distributeurId);

      // ✅ Store Selected Agency ID
      String agencyId = selectedAgency?["agence_unique_id"] ?? "Unknown";
      await prefs.setString('agency_id', agencyId);

      // ✅ Debugging logs
      print("✅ [DEBUG] Stored Distributeur ID: $distributeurId");
      print("✅ [DEBUG] Stored Agency ID: $agencyId");

      // 🚨 Retrieve immediately after storing to verify
      String? retrievedAgencyId = prefs.getString('agency_id');
      print("🔍 [DEBUG] Retrieved Agency ID after saving: $retrievedAgencyId");

      // ✅ Navigate to DistributorSwap with correct parameters
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DistributorSwap(
            loggedInUser: widget.loggedInUser,
            distributorId: distributeurId,
            agencyId: retrievedAgencyId ?? "Unknown",
          ),
        ),
      );
    } catch (error) {
      print("❌ [ERROR] Failed to process data: $error");
      // Show an error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: Unable to proceed. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isButtonLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userName = "${widget.loggedInUser['name'] ?? 'Unknown'} ${widget.loggedInUser['prenom'] ?? ''}";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Select an Agency"),
        backgroundColor: AppColors.primaryYellow,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome User
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryYellow,
                      child: Icon(Icons.person, color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select an Agency",
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        Text(
                          userName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Search Box with Clear Button
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search by Name or Unique ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
                    : null,
              ),
              onChanged: _filterAgencies,
            ),
            const SizedBox(height: 10),

            // Show loading or agency list
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: AppColors.primaryYellow),
                ),
              )
            else if (filteredList.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text("No agencies found."),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final agency = filteredList[index];
                    final isSelected = selectedIndex == index;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: isSelected ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isSelected
                            ? const BorderSide(color: AppColors.primaryYellow, width: 2)
                            : BorderSide.none,
                      ),
                      color: isSelected ? Colors.yellow[50] : Colors.white,
                      child: ListTile(
                        onTap: () => _selectAgency(agency, index),
                        leading: const Icon(Icons.store, color: Colors.green),
                        title: Text(agency["nom_agence"] ?? "Unknown"),
                        subtitle: Text("${agency["ville"] ?? "Unknown"}, ${agency["agence_unique_id"] ?? "N/A"}"),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppColors.primaryYellow)
                            : null,
                      ),
                    );
                  },
                ),
              ),

            // Modern Next Button with Progress Indicator
            if (showNextButton)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    // Linear progress indicator that appears during loading
                    if (isButtonLoading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                          minHeight: 6,
                        ),
                      ),
                    ElevatedButton(
                      onPressed: isButtonLoading ? null : _onNextPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(
                        isButtonLoading ? "LOADING..." : "NEXT",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}