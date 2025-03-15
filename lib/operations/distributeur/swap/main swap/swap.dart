import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DistributorSwap extends StatefulWidget {
  final Map<String, dynamic> loggedInUser;
  final String agencyId;
  final String distributorId;

  const DistributorSwap({
    Key? key,
    required this.loggedInUser,
    required this.agencyId,
    required this.distributorId,
  }) : super(key: key);

  @override
  State<DistributorSwap> createState() => _DistributorSwapState();
}

class _DistributorSwapState extends State<DistributorSwap> {
  final TextEditingController _outgoingSearchController =
      TextEditingController();
  final TextEditingController _incomingSearchController =
      TextEditingController();

  final Set<String> _selectedOutgoingBatteries = {};
  final Set<String> _selectedIncomingBatteries = {};

  List<Map<String, dynamic>> distributorBatteries = [];
  List<Map<String, dynamic>> agentBatteries = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    print("🔍 [DEBUG] Received Agency ID: ${widget.agencyId}");
    print("🔍 [DEBUG] Received Distributor ID: ${widget.distributorId}");
    fetchBatteriesDistributeur();
    fetchBatteriesAgence();
  }

  @override
  void dispose() {
    _outgoingSearchController.dispose();
    _incomingSearchController.dispose();
    super.dispose();
  }

  void _showBatteryDetails(Map<String, dynamic> battery, bool isOutgoing) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isOutgoing
                ? 'Outgoing Battery Details'
                : 'Incoming Battery Details',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.qr_code,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'MAC ID: ${battery['mac_id'] ?? 'Unknown'}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.numbers,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Battery ID: ${battery['id'] ?? 'Unknown'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue[700],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showSwapConfirmationDialog() async {
    List<Map<String, dynamic>> selectedOutgoingBatteriesData =
        distributorBatteries
            .where(
                (battery) => _selectedOutgoingBatteries.contains(battery['id']))
            .toList();

    List<Map<String, dynamic>> selectedIncomingBatteriesData = agentBatteries
        .where((battery) => _selectedIncomingBatteries.contains(battery['id']))
        .toList();

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            final mediaQuery = MediaQuery.of(context);
            final screenWidth = mediaQuery.size.width;
            final screenHeight = mediaQuery.size.height;
            final isLandscape = screenWidth > screenHeight;

            // Adjust dialog width based on orientation and screen size
            final dialogWidth = isLandscape
                ? screenWidth * 0.6
                : (screenWidth > 600 ? 600.0 : screenWidth * 0.9);

            return AlertDialog(
              title: const Text(
                'Confirm Battery Swap',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: Container(
                width: dialogWidth,
                constraints: BoxConstraints(
                  maxHeight:
                      isLandscape ? screenHeight * 0.8 : screenHeight * 0.6,
                  maxWidth: dialogWidth,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You are about to swap:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (selectedOutgoingBatteriesData.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Outgoing Batteries (${selectedOutgoingBatteriesData.length}):',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...selectedOutgoingBatteriesData.map(
                                (battery) => ListTile(
                                  dense: true,
                                  title: Text('MAC ID: ${battery['mac_id']}',
                                      overflow: TextOverflow.ellipsis),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.info_outline,
                                        size: 20),
                                    onPressed: () =>
                                        _showBatteryDetails(battery, true),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (selectedIncomingBatteriesData.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Incoming Batteries (${selectedIncomingBatteriesData.length}):',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...selectedIncomingBatteriesData.map(
                                (battery) => ListTile(
                                  dense: true,
                                  title: Text('MAC ID: ${battery['mac_id']}',
                                      overflow: TextOverflow.ellipsis),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.info_outline,
                                        size: 20),
                                    onPressed: () =>
                                        _showBatteryDetails(battery, false),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Confirm Swap'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> fetchBatteriesDistributeur() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Use the passed distributorId instead of getting it from SharedPreferences
      String distributeurId = widget.distributorId;

      print("🔍 [DEBUG] Using Distributor ID: $distributeurId");

      if (distributeurId.isEmpty || distributeurId == "Unknown") {
        print(
            "⚠️ [WARNING] No valid Distributeur ID. Defaulting to empty list.");
        setState(() {
          distributorBatteries = [];
          isLoading = false;
          errorMessage = "No valid Distributeur ID found";
        });
        return;
      }

      print(
          "🌍 [API CALL] Fetching batteries for Distributeur ID: $distributeurId");
      print(
          "🌍 [API CALL] URL: http://10.0.2.2:3010/api/distributeur/$distributeurId");

      final response = await http.get(
        Uri.parse(
            "http://10.0.2.2:3010/api/distributorswapbatteries/$distributeurId"),
        headers: {'Content-Type': 'application/json'},
      );

      print("📩 [RESPONSE] Status Code: ${response.statusCode}");
      print("📦 [RAW RESPONSE] ${response.body}");

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);

        if (decodedData["success"] != true ||
            decodedData["batteries"] is! List) {
          throw Exception("Invalid API response format");
        }

        List<Map<String, dynamic>> batteries =
            (decodedData["batteries"] as List).map((battery) {
          final macId = battery["mac_id"]?.toString() ?? "Unknown";
          return {
            'id': battery["id"]?.toString() ?? "Unknown ID",
            'mac_id': macId,
          };
        }).toList();

        setState(() {
          distributorBatteries = batteries;
          isLoading = false;
        });

        print(
            "✅ [SUCCESS] Loaded ${batteries.length} batteries for Distributeur.");
      } else {
        print(
            "⚠️ [ERROR] Failed to load distributor batteries: ${response.statusCode}");
        setState(() {
          distributorBatteries = [];
          isLoading = false;
          errorMessage = "Failed to load batteries: ${response.statusCode}";
        });
      }
    } catch (error) {
      print("❌ [ERROR] Fetching Distributeur batteries failed: $error");
      setState(() {
        distributorBatteries = [];
        isLoading = false;
        errorMessage = "Error loading batteries: $error";
      });
    }
  }

  Future<void> fetchBatteriesAgence() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      String agenceId = widget.agencyId;

      print("🔍 [DEBUG] Using Agency ID: $agenceId");

      if (agenceId.isEmpty || agenceId == "Unknown") {
        print("⚠️ [WARNING] No valid Agence ID. Defaulting to empty list.");
        setState(() {
          agentBatteries = [];
          isLoading = false;
          errorMessage = "No valid Agence ID found";
        });
        return;
      }

      final apiUrl = "http://10.0.2.2:3010/api/batteries/agencedist/$agenceId";
      print("🌍 [API CALL] Fetching batteries from: $apiUrl");

      final response = await http.get(Uri.parse(apiUrl));

      print("📩 [DEBUG] API Response Status Code: ${response.statusCode}");
      print("📦 [DEBUG] Raw Response: ${response.body}");

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);

        List<Map<String, dynamic>> batteries = (decodedData["batteries"] as List)
            .map((battery) {
          final macId = battery["mac_id"]?.toString() ?? "Unknown";
          return {
            'id': battery["id"]?.toString() ?? macId,
            'mac_id': macId,
          };
        }).toList();

        setState(() {
          agentBatteries = batteries;
          isLoading = false;
        });

        print("✅ [SUCCESS] Loaded ${batteries.length} batteries for Agence.");
      } else {
        print("⚠️ [ERROR] API responded with status code: ${response.statusCode}");
        setState(() {
          agentBatteries = [];
          isLoading = false;
          errorMessage = "Failed to load batteries: ${response.statusCode}";
        });
      }
    } catch (error) {
      print("❌ [ERROR] Fetching Agence batteries failed: $error");
      setState(() {
        agentBatteries = [];
        isLoading = false;
        errorMessage = "Error loading batteries: $error";
      });
    }
  }

  Future<void> swapBatteries() async {
    // Show confirmation dialog first
    bool confirmed = await _showSwapConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Use the passed distributorId and agencyId instead of getting from SharedPreferences
      String distributeurId = widget.distributorId;
      String agenceId = widget.agencyId;

      print(
          "🔍 [DEBUG] distributeur_id: $distributeurId, agence_id: $agenceId");

      if (distributeurId.isEmpty || agenceId.isEmpty) {
        print("⚠️ [ERROR] Missing required values.");
        throw Exception("Missing required distributor or agency ID");
      }

      List<String> outgoingMacIds = _selectedOutgoingBatteries
          .map((id) =>
              distributorBatteries
                  .firstWhere((battery) => battery['id'] == id)['mac_id']
                  ?.toString() ??
              '')
          .where((macId) => macId.isNotEmpty)
          .toList();

      List<String> incomingMacIds = _selectedIncomingBatteries
          .map((id) =>
              agentBatteries
                  .firstWhere((battery) => battery['id'] == id)['mac_id']
                  ?.toString() ??
              '')
          .where((macId) => macId.isNotEmpty)
          .toList();

      print("📦 [DEBUG] Outgoing MAC IDs: $outgoingMacIds");
      print("📥 [DEBUG] Incoming MAC IDs: $incomingMacIds");

      final Uri apiUrl =
          Uri.parse("http://10.0.2.2:3010/api/distributeuragenceswap");
      final response = await http.post(
        apiUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "distributeurId": distributeurId,
          "agenceId": agenceId,
          "outgoingMacIds": outgoingMacIds,
          "incomingMacIds": incomingMacIds
        }),
      );

      final decodedData = json.decode(response.body);

      if (response.statusCode == 200 && decodedData["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Swap successful!"),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _selectedOutgoingBatteries.clear();
          _selectedIncomingBatteries.clear();
        });

        await fetchBatteriesDistributeur();
        await fetchBatteriesAgence();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decodedData["message"] ?? "Swap failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _filterBatteries(
      List<Map<String, dynamic>> batteries, String query) {
    if (query.isEmpty) return batteries;

    return batteries.where((battery) {
      final macId = battery['mac_id'];
      if (macId == null) return false;
      return macId.toString().toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  Widget _buildSearchBar(TextEditingController controller, String placeholder) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: placeholder,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildBatteryList(
    List<Map<String, dynamic>> batteries,
    String searchText,
    Set<String> selectedSet,
    bool isOutgoing,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Failed to load batteries',
                style: TextStyle(color: Colors.red[700])),
            const SizedBox(height: 4),
            Text(errorMessage!,
                style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isOutgoing
                  ? fetchBatteriesDistributeur
                  : fetchBatteriesAgence,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredBatteries = _filterBatteries(batteries, searchText);

    if (filteredBatteries.isEmpty) {
      return const Center(
        child: Text('No batteries found'),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: filteredBatteries.length,
        padding: const EdgeInsets.all(8.0),
        itemBuilder: (context, index) {
          final battery = filteredBatteries[index];
          final isSelected = selectedSet.contains(battery['id']);
          final displayText = battery['mac_id'] ?? 'Unknown MAC';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
              leading: Checkbox(
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      if (isOutgoing) {
                        _selectedOutgoingBatteries.add(battery['id']);
                      } else {
                        _selectedIncomingBatteries.add(battery['id']);
                      }
                    } else {
                      if (isOutgoing) {
                        _selectedOutgoingBatteries.remove(battery['id']);
                      } else {
                        _selectedIncomingBatteries.remove(battery['id']);
                      }
                    }
                  });
                },
              ),
              title: Text(
                displayText,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                onPressed: () => _showBatteryDetails(battery, isOutgoing),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedBatteriesSection(
      String title,
      Set<String> selectedBatteries,
      List<Map<String, dynamic>> allBatteries,
      BoxConstraints constraints) {
    final selectedBatteriesData = allBatteries
        .where((battery) => selectedBatteries.contains(battery['id']))
        .toList();

    // Determine height based on available space
    final sectionHeight = constraints.maxHeight * 0.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: BoxConstraints(minHeight: 60, maxHeight: sectionHeight),
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: selectedBatteriesData.isEmpty
              ? const Center(child: Text('No batteries selected'))
              : LayoutBuilder(builder: (context, constraints) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedBatteriesData.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final battery = selectedBatteriesData[index];
                      final displayText = battery['mac_id'] ?? 'Unknown MAC';

                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Constrain text width to prevent overflow
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth * 0.7 -
                                    24, // Account for close icon
                              ),
                              child: Text(
                                displayText,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (title.contains('Outgoing')) {
                                    _selectedOutgoingBatteries
                                        .remove(battery['id']);
                                  } else {
                                    _selectedIncomingBatteries
                                        .remove(battery['id']);
                                  }
                                });
                              },
                              child: const Icon(Icons.close, size: 16),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen information
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isLandscape = screenSize.width > screenSize.height;
    final bool isSmallScreen = screenSize.width < 600;

    // For highly responsive sizing
    final availableHeight = screenSize.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom -
        kToolbarHeight;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Distributor Swap"),
        backgroundColor: Colors.yellow,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              fetchBatteriesDistributeur();
              fetchBatteriesAgence();
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
            child: Column(
              children: [
                // Selected Batteries Card - Dynamic sizing based on orientation
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected Batteries',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 8.0 : 16.0),
                        _buildSelectedBatteriesSection(
                          'Selected Outgoing Batteries',
                          _selectedOutgoingBatteries,
                          distributorBatteries,
                          constraints,
                        ),
                        SizedBox(height: isSmallScreen ? 8.0 : 16.0),
                        _buildSelectedBatteriesSection(
                          'Selected Incoming Batteries',
                          _selectedIncomingBatteries,
                          agentBatteries,
                          constraints,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8.0 : 16.0),

                // Battery Selection Area - Adapts to device orientation
                Expanded(
                  child: (!isLandscape && isSmallScreen) ||
                          (isSmallScreen && screenSize.height < 600)
                      ? // Vertical layout for small portrait screens
                      Column(
                          children: [
                            // Outgoing Batteries
                            Expanded(
                              child: Card(
                                elevation: 4,
                                child: Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      color: Colors.blue[100],
                                      padding: const EdgeInsets.all(8.0),
                                      child: const Text(
                                        'Outgoing Batteries',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    _buildSearchBar(_outgoingSearchController,
                                        'Search outgoing batteries...'),
                                    _buildBatteryList(
                                      distributorBatteries,
                                      _outgoingSearchController.text,
                                      _selectedOutgoingBatteries,
                                      true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Incoming Batteries
                            Expanded(
                              child: Card(
                                elevation: 4,
                                child: Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      color: Colors.green[100],
                                      padding: const EdgeInsets.all(8.0),
                                      child: const Text(
                                        'Incoming Batteries',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    _buildSearchBar(_incomingSearchController,
                                        'Search incoming batteries...'),
                                    _buildBatteryList(
                                      agentBatteries,
                                      _incomingSearchController.text,
                                      _selectedIncomingBatteries,
                                      false,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : // Horizontal layout for landscape or larger screens
                      Row(
                          children: [
                            Expanded(
                              child: Card(
                                elevation: 4,
                                child: Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      color: Colors.blue[100],
                                      padding: const EdgeInsets.all(8.0),
                                      child: const Text(
                                        'Outgoing Batteries',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    _buildSearchBar(_outgoingSearchController,
                                        'Search outgoing batteries...'),
                                    _buildBatteryList(
                                      distributorBatteries,
                                      _outgoingSearchController.text,
                                      _selectedOutgoingBatteries,
                                      true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 8.0 : 16.0),
                            Expanded(
                              child: Card(
                                elevation: 4,
                                child: Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      color: Colors.green[100],
                                      padding: const EdgeInsets.all(8.0),
                                      child: const Text(
                                        'Incoming Batteries',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    _buildSearchBar(_incomingSearchController,
                                        'Search incoming batteries...'),
                                    _buildBatteryList(
                                      agentBatteries,
                                      _incomingSearchController.text,
                                      _selectedIncomingBatteries,
                                      false,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),

                SizedBox(height: isSmallScreen ? 8.0 : 16.0),

                // Swap Button - Responsive width and padding
                LayoutBuilder(builder: (context, constraints) {
                  final buttonWidth = isSmallScreen
                      ? constraints.maxWidth
                      : constraints.maxWidth * (isLandscape ? 0.4 : 0.5);

                  return SizedBox(
                    width: buttonWidth,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        print("🔘 [DEBUG] Swap button pressed.");
                        swapBatteries();
                      },
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text(
                        'SWAP BATTERIES',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 16 : 32,
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                      ),
                    ),
                  );
                }),
                SizedBox(height: isSmallScreen ? 8.0 : 16.0),
              ],
            ),
          );
        },
      ),
    );
  }
}
