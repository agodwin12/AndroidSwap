import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swap/operations/agence/dashboard/widget/colors.dart';
import '../DistributeurSwap.dart';
import '../swap_screen.dart';

class SwapType extends StatefulWidget {
  final Map<String, dynamic> loggedInUser;

  const SwapType({Key? key, required this.loggedInUser}) : super(key: key);

  @override
  _SwapTypeState createState() => _SwapTypeState();
}

class _SwapTypeState extends State<SwapType> {
  String? selectedSwapType;
  Map<String, dynamic>? selectedEntity;
  List<Map<String, dynamic>> entityList = [];
  List<Map<String, dynamic>> filteredList = [];
  TextEditingController searchController = TextEditingController();
  bool showNextButton = false;
  bool isLoading = false;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
  }

  /// **Handles Swap Type Selection & Fetches Entities**
  void _onSwapTypeSelected(String? value) async {
    setState(() {
      selectedSwapType = value;
      selectedEntity = null;
      selectedIndex = null;
      entityList = [];
      filteredList = [];
      showNextButton = false;
      isLoading = true;
      searchController.clear();
    });

    await _fetchEntities(value);
  }

  /// **Fetch Entities from Backend**
  Future<void> _fetchEntities(String? swapType) async {
    if (swapType == null) return;

    final String apiUrl = swapType == "Distributor"
        ? "http://57.128.178.119:3010/api/swaps/distributors"
        : "http://57.128.178.119:3010/api/swaps/agencies";

    try {
      print("🌍 [API CALL] Fetching data from: $apiUrl");

      final response = await http.get(Uri.parse(apiUrl), headers: {'Content-Type': 'application/json'});

      print("📩 [DEBUG] Response Status: ${response.statusCode}");
      print("🔍 [DEBUG] Raw Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(response.body);

        setState(() {
          entityList = decodedData.map((e) => Map<String, dynamic>.from(e)).toList();
          filteredList = List.from(entityList);
          isLoading = false;
        });
      } else {
        print("❌ [ERROR] Failed to fetch entities");
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

  /// **Handles "Next" Button Press**
  void _onNextPressed() async {
    if (selectedEntity == null) {
      print("❌ [ERROR] No entity selected!");
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Convert `id` to String explicitly
    String entityId = selectedEntity?["id"].toString() ?? "Unknown";

    await prefs.setString('selected_destination', jsonEncode(selectedEntity));
    await prefs.setString('entity_id', entityId);

    print("✅ [INFO] Stored Selected Destination: ${selectedEntity?["nom_agence"] ?? selectedEntity?["nom"]} ${selectedEntity?["prenom"] ?? ""}");
    print("✅ [INFO] Stored Entity ID: $entityId");

    if (selectedSwapType == "Distributor") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DistributeurSwapEntrepot(
            selectedSwapType: selectedSwapType!,
            uniqueId: widget.loggedInUser["unique_id"],
            loggedInUser: widget.loggedInUser,
            distributeurId: entityId,
            idEntrepot: widget.loggedInUser["id_entrepot"]?.toString() ?? "Unknown",
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EntrepotSwap(
            selectedSwapType: selectedSwapType!,
            uniqueId: widget.loggedInUser["unique_id"],
            loggedInUser: widget.loggedInUser,
            agenceUniqueId: entityId,
            idEntrepot: widget.loggedInUser["id_entrepot"]?.toString() ?? "Unknown",
            distributeurId: "Unknown",
          ),
        ),
      );
    }
  }

  /// **Selects Entity and Updates Search Field**
  void _selectEntity(Map<String, dynamic> entity, int index) {
    final bool isDistributor = selectedSwapType == "Distributor";
    final String displayName = isDistributor
        ? "${entity["nom"] ?? "Unknown"} ${entity["prenom"] ?? ""}".trim()
        : entity["nom_agence"] ?? "Unknown";

    setState(() {
      selectedEntity = entity;
      selectedIndex = index;
      showNextButton = true;
      searchController.text = displayName;
    });
  }

  /// **Filters Search Results**
  void _filterEntities(String query) {
    setState(() {
      filteredList = entityList.where((entity) {
        final bool isDistributor = selectedSwapType == "Distributor";

        final name = isDistributor
            ? "${entity["nom"] ?? ""} ${entity["prenom"] ?? ""}".trim()
            : entity["nom_agence"] ?? "";

        final id = isDistributor
            ? entity["distributeur_unique_id"] ?? ""
            : entity["agence_unique_id"] ?? "";

        return name.toLowerCase().contains(query.toLowerCase()) ||
            id.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final String userName = "${widget.loggedInUser['name'] ?? 'Unknown'} ${widget.loggedInUser['prenom'] ?? ''}";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Swap Battery"),
        backgroundColor: AppColors.primaryYellow,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
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
                          "Select a desitination,",
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

            // Swap Type Selection
            Text(
              "Choose Swap Destination",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: selectedSwapType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                hint: const Text("Select Destination Type"),
                icon: const Icon(Icons.arrow_drop_down_circle, color: AppColors.primaryYellow),
                items: [
                  DropdownMenuItem(
                    value: "Distributor",
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        const Text("Distributor"),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: "Agency",
                    child: Row(
                      children: [
                        Icon(Icons.store, color: Colors.green[700], size: 20),
                        const SizedBox(width: 8),
                        const Text("Agency"),
                      ],
                    ),
                  ),
                ],
                onChanged: _onSwapTypeSelected,
              ),
            ),
            const SizedBox(height: 20),

            if (isLoading)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primaryYellow),
                      SizedBox(height: 16),
                      Text("Loading destinations...", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),

            if (!isLoading && selectedSwapType != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Search & Select ${selectedSwapType == "Distributor" ? "Distributor" : "Agency"}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // Search Box
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          hintText: "Search by name or ID",
                          prefixIcon: const Icon(Icons.search, color: AppColors.primaryYellow),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              searchController.clear();
                              _filterEntities("");
                            },
                          )
                              : null,
                        ),
                        onChanged: _filterEntities,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Results Count
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                      child: Text(
                        "${filteredList.length} ${selectedSwapType == "Distributor" ? "distributors" : "agencies"} found",
                        style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                      ),
                    ),

                    // Entity List
                    Expanded(
                      child: filteredList.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              "No ${selectedSwapType == "Distributor" ? "distributors" : "agencies"} found",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final entity = filteredList[index];
                          final isDistributor = selectedSwapType == "Distributor";
                          final isSelected = selectedIndex == index;

                          // Get entity details
                          final String name = isDistributor
                              ? "${entity["nom"] ?? "Unknown"} ${entity["prenom"] ?? ""}".trim()
                              : entity["nom_agence"] ?? "Unknown";
                          final String id = isDistributor
                              ? entity["distributeur_unique_id"] ?? "N/A"
                              : entity["agence_unique_id"] ?? "N/A";
                          final String location = "${entity["ville"] ?? "Unknown"}, ${entity["quartier"] ?? "N/A"}";

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                            elevation: isSelected ? 4 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isSelected
                                  ? const BorderSide(color: AppColors.primaryYellow, width: 2)
                                  : BorderSide.none,
                            ),
                            color: isSelected ? Colors.yellow[50] : Colors.white,
                            child: InkWell(
                              onTap: () => _selectEntity(entity, index),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    // Icon based on type
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: isDistributor ? Colors.blue[50] : Colors.green[50],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          isDistributor ? Icons.person : Icons.store,
                                          color: isDistributor ? Colors.blue[700] : Colors.green[700],
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Entity details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "ID: $id",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.location_on,
                                                  size: 14,
                                                  color: Colors.grey[600]
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                location,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Selection indicator
                                    if (isSelected)
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryYellow,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Next Button
            if (showNextButton)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  onPressed: _onNextPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    "NEXT",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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