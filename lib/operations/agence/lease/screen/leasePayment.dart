import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class CollectPaymentScreen extends StatefulWidget {
  final String agenceId;
  final String uniqueId;
  final String fullName;
  final String userType;
  final String email;
  final String location;

  const CollectPaymentScreen({
    Key? key,
    required this.agenceId,
    required this.uniqueId,
    required this.fullName,
    required this.userType,
    required this.email,
    required this.location,
  }) : super(key: key);

  @override
  _CollectPaymentScreenState createState() => _CollectPaymentScreenState();
}

class _CollectPaymentScreenState extends State<CollectPaymentScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _leaseAmountController = TextEditingController();
  final TextEditingController _batteryCautionController = TextEditingController();

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  Map<String, dynamic>? selectedUser;
  List<Map<String, dynamic>> userMotos = [];
  Map<String, dynamic>? selectedMotoDetails;
  bool isLoading = false;
  String? errorMessage;
  bool showConfirmation = false;
  bool showReceipt = false;
  bool showMotoSelection = false;

  // Payment details
  int leaseAmount = 0;
  int batteryCaution = 0;
  int totalAmount = 0;

  final String baseUrl = "http://10.0.2.2:3010/api"; // Local API URL

  String _getInitials(Map<String, dynamic> user) {
    String nom = user["nom"] ?? "";
    String prenom = user["prenom"] ?? "";

    String initials = "";
    if (nom.isNotEmpty) initials += nom[0];
    if (prenom.isNotEmpty) initials += prenom[0];

    return initials.isNotEmpty ? initials : "??";
  }

  /// Fetch all users
  Future<void> fetchAllUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/users'));
      if (response.statusCode == 200) {
        setState(() {
          users = List<Map<String, dynamic>>.from(json.decode(response.body));
          filteredUsers = List.from(users);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error loading users: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  /// Fetch user by phone
  Future<void> fetchUserByPhone(String phone) async {
    if (phone.isEmpty) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/moto/$phone'));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print("🔍 API Response: $data"); // Debugging

        // Extract user details correctly
        if (data is Map && data.containsKey("user")) {
          var userInfo = data["user"];
          selectedUser = {
            "name": "${userInfo["nom"] ?? "Unknown"} ${userInfo["prenom"] ??
                ""}".trim(),
            "nom": userInfo["nom"] ?? "Unknown",
            "prenom": userInfo["prenom"] ?? "",
            "phone": userInfo["phone"] ?? phone,
          };
        }

        // Extract moto details
        List<dynamic> motoList = data["motos"] ?? [];
        userMotos = List<Map<String, dynamic>>.from(motoList);

        setState(() {
          if (userMotos.isNotEmpty) {
            selectedMotoDetails = null; // Let user choose a moto
            showMotoSelection = true;
          } else {
            selectedMotoDetails = null;
            showMotoSelection = false;
          }
        });
      } else {
        setState(() {
          errorMessage = "User not found.";
          selectedUser = null;
          selectedMotoDetails = null;
          userMotos = [];
          showMotoSelection = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching details: ${e.toString()}";
        selectedUser = null;
        selectedMotoDetails = null;
        userMotos = [];
        showMotoSelection = false;
      });
    }

    setState(() => isLoading = false);
  }

  /// Select a specific moto
  void selectMoto(Map<String, dynamic> moto) {
    setState(() {
      selectedMotoDetails = moto;
      showMotoSelection = false;
    });
  }

  /// Filter users based on search text
  void filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = List.from(users);
      } else {
        filteredUsers = users.where((user) {
          final String name = "${user["nom"]} ${user["prenom"]}".toLowerCase();
          final String phone = user["phone"].toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || phone.contains(searchLower);
        }).toList();
      }
    });
  }

  /// Calculate total amount
  void calculateTotal() {
    setState(() {
      leaseAmount = int.tryParse(_leaseAmountController.text) ?? 0;
      batteryCaution = int.tryParse(_batteryCautionController.text) ?? 0;
      totalAmount = leaseAmount + batteryCaution;
    });
  }

  /// Process payment and show confirmation dialog
  void processPayment() async {
    // Validate amounts
    if (leaseAmount < 3500) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lease amount must be at least 3,500 FCFA')));
      return;
    }
    if (batteryCaution < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Battery caution must be at least 500 FCFA')));
      return;
    }
    if (selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a user first')));
      return;
    }
    if (selectedMotoDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a motorcycle first')));
      return;
    }

    calculateTotal(); // Ensure totalAmount is updated

    // Show confirmation dialog
    setState(() {
      showConfirmation = true;
    });
  }

  /// Confirm payment and show receipt
  void confirmPaymentReceipt() {
    setState(() {
      showConfirmation = false;
      showReceipt = true;
    });
  }

  /// Show PIN validation dialog
  Future<void> _showPinValidationDialog() async {
    final TextEditingController _pinController = TextEditingController();
    bool _isValidating = false;
    String _errorMessage = '';

    const String correctPin = '1234'; // This should be replaced with actual PIN validation

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Enter PIN to Complete Payment',
                style: TextStyle(
                    color: Color(0xFFDCDB32), fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _pinController,
                      decoration: InputDecoration(
                        labelText: 'Enter 4-digit PIN',
                        errorText: _errorMessage.isNotEmpty
                            ? _errorMessage
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius
                            .circular(10)),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      onChanged: (value) {
                        if (_errorMessage.isNotEmpty) {
                          setState(() {
                            _errorMessage = '';
                          });
                        }

                        // Auto-validate when 4 digits are entered
                        if (value.length == 4) {
                          if (value == correctPin) {
                            Navigator.of(context).pop();
                            saveLeasePayment(); // Save payment after PIN validation
                          } else {
                            setState(() {
                              _errorMessage = 'Invalid PIN. Please try again.';
                              _pinController.clear();
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                      'CANCEL', style: TextStyle(color: Colors.grey[700])),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Save lease payment to API
  Future<void> saveLeasePayment() async {
    final String apiUrl = "$baseUrl/payments/lease";

    Map<String, dynamic> paymentData = {
      "id_moto": selectedMotoDetails!["moto_unique_id"], // Moto ID
      "montant_lease": leaseAmount,
      "montant_battery": batteryCaution,
      "id_user_agence": widget.uniqueId, // Use unique ID from logged-in user
    };

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(paymentData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Payment recorded successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        completeTransaction(); // Reset UI after successful payment
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving payment: ${e.toString()}")),
      );
    }

    setState(() => isLoading = false);
  }

  /// Complete the transaction
  Future<void> completeTransaction() async {
    setState(() => isLoading = true);

    // Simulate API call
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      isLoading = false;
      showReceipt = false;
      // Reset for a new transaction
      selectedUser = null;
      selectedMotoDetails = null;
      userMotos = [];
      showMotoSelection = false;
      _searchController.clear();
      _leaseAmountController.clear();
      _batteryCautionController.clear();
      leaseAmount = 0;
      batteryCaution = 0;
      totalAmount = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment completed successfully!'),
            backgroundColor: Colors.green)
    );
  }

  @override
  void initState() {
    super.initState();
    fetchAllUsers(); // Load all users initially

    _searchController.addListener(() {
      filterUsers(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _leaseAmountController.dispose();
    _batteryCautionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Collect Payment"),
        backgroundColor: Color(0xFFDCDB32),
        elevation: 0,
      ),
      body: isLoading && !showConfirmation && !showReceipt && !showMotoSelection
          ? Center(child: CircularProgressIndicator())
          : showConfirmation
          ? _buildConfirmationView()
          : showReceipt
          ? _buildReceiptView()
          : showMotoSelection
          ? _buildMotoSelectionView()
          : _buildMainView(),
    );
  }

  Widget _buildMainView() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Box
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by name or phone",
                prefixIcon: Icon(Icons.search, color: Colors.indigo),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          SizedBox(height: 16),

          // Selected User and Moto Info
          if (selectedUser != null && selectedMotoDetails != null) ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Selected User",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            showMotoSelection = true;
                          });
                        },
                        child: Text(
                          "Change Motorcycle",
                          style: TextStyle(
                            color: Colors.indigo,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        selectedUser!["name"],
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        selectedUser!["phone"],
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.directions_bike, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        "VIN: ${selectedMotoDetails!["vin"]}",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.badge, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        "Model: ${selectedMotoDetails!["model"]}",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.qr_code, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        "ID: ${selectedMotoDetails!["moto_unique_id"]}",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Payment Info
            Text(
              "Payment Details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            SizedBox(height: 12),

            // Lease Amount Field
            TextField(
              controller: _leaseAmountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: "Lease Amount (min. 3,500 FCFA)",
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixText: "FCFA",
              ),
              onChanged: (value) {
                calculateTotal();
              },
            ),

            SizedBox(height: 12),

            // Battery Caution Field
            TextField(
              controller: _batteryCautionController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: "Battery Caution (min. 500 FCFA)",
                prefixIcon: Icon(Icons.battery_charging_full),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixText: "FCFA",
              ),
              onChanged: (value) {
                calculateTotal();
              },
            ),

            SizedBox(height: 24),

            // Pay Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: processPayment,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "PAY LEASE",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFDCDB32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ],

          // User List
          if (selectedUser == null || filteredUsers.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                selectedUser == null
                    ? "Select a User"
                    : "Or Select Another User",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ),

          // Error Message
          if (errorMessage != null)
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ),

          // User List
          Expanded(
            child: filteredUsers.isEmpty
                ? Center(
              child: Text(
                "No users found",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
                : ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFFDCDB32),
                      child: Text(
                        _getInitials(user),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      "${user["nom"]} ${user["prenom"]}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(user["phone"]),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      fetchUserByPhone(user["phone"]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotoSelectionView() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    showMotoSelection = false;
                  });
                },
              ),
              Text(
                "Select A Bike To Pay",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDCDB32),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // User Info Header
          if (selectedUser != null)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text(
                    "${selectedUser!["name"]} (${selectedUser!["phone"]})",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 16),

          Expanded(
            child: userMotos.isEmpty
                ? Center(
              child: Text(
                "No motorcycles found for this user",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            )
                : ListView.builder(
              itemCount: userMotos.length,
              itemBuilder: (context, index) {
                final moto = userMotos[index];
                return Card(
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      selectMoto(moto);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.directions_bike,
                                      color: Colors.indigo, size: 28),
                                  SizedBox(width: 12),
                                  Text(
                                    moto["model"] ?? "No Model",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 24,
                              ),
                            ],
                          ),
                          Divider(height: 24),
                          _buildMotoInfoRow(
                            Icons.qr_code,
                            "ID",
                            moto["moto_unique_id"] ?? "N/A",
                          ),
                          SizedBox(height: 8),
                          _buildMotoInfoRow(
                            Icons.fingerprint,
                            "VIN",
                            moto["vin"] ?? "N/A",
                          ),
                          SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                selectMoto(moto);
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  "SELECT",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFDCDB32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
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
    );
  }

  Widget _buildMotoInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 18,
        ),
        SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Payment confirmation view
  Widget _buildConfirmationView() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 72,
            color: Colors.green,
          ),
          SizedBox(height: 20),
          Text(
            "Payment Summary",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDCDB32),
            ),
          ),
          SizedBox(height: 30),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // User details
                _buildSummaryRow("Nom", selectedUser?["nom"] ?? "N/A"),
                _buildSummaryRow("Prenom", selectedUser?["prenom"] ?? "N/A"),
                _buildSummaryRow("Phone", selectedUser?["phone"] ?? "N/A"),

                // Motorcycle details
                _buildSummaryRow(
                    "Model", selectedMotoDetails?["model"] ?? "N/A"),
                _buildSummaryRow("VIN", selectedMotoDetails?["vin"] ?? "N/A"),
                _buildSummaryRow(
                    "Moto ID", selectedMotoDetails?["moto_unique_id"] ?? "N/A"),

                Divider(height: 30),

                // Payment details
                _buildSummaryRow(
                    "Lease Amount", "$leaseAmount FCFA", isBold: true),
                _buildSummaryRow(
                    "Battery Caution", "$batteryCaution FCFA", isBold: true),

                Divider(height: 30),

                // Total
                _buildSummaryRow("Total", "$totalAmount FCFA", isTotal: true),
              ],
            ),
          ),
          Spacer(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showConfirmation = false;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text("CANCEL"),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: confirmPaymentReceipt,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text("CONFIRM"),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptView() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 72,
            color: Color(0xFFDCDB32),
          ),
          SizedBox(height: 20),
          Text(
            "Payment Receipt",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDCDB32),
            ),
          ),
          SizedBox(height: 30),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Color(0xFFDCDB32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // User details
                _buildSummaryRow("Nom", selectedUser?["nom"] ?? "N/A"),
                _buildSummaryRow("Prenom", selectedUser?["prenom"] ?? "N/A"),
                _buildSummaryRow("Phone", selectedUser?["phone"] ?? "N/A"),

                // Motorcycle details
                _buildSummaryRow(
                    "Model", selectedMotoDetails?["model"] ?? "N/A"),
                _buildSummaryRow("VIN", selectedMotoDetails?["vin"] ?? "N/A"),
                _buildSummaryRow(
                    "Moto ID", selectedMotoDetails?["moto_unique_id"] ?? "N/A"),

                Divider(height: 30),

                // Payment details
                _buildSummaryRow(
                    "Lease Amount", "$leaseAmount FCFA", isBold: true),
                _buildSummaryRow(
                    "Battery Caution", "$batteryCaution FCFA", isBold: true),

                Divider(height: 30),

                // Total
                _buildSummaryRow(
                    "Total Paid", "$totalAmount FCFA", isTotal: true),

                SizedBox(height: 20),
                Text(
                  "I confirm that I have received the total amount of $totalAmount FCFA",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Show PIN validation dialog when PAY LEASE button is pressed
                _showPinValidationDialog();
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  "PAY LEASE",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Helper widget for summary rows in confirmation and receipt views
  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: isBold || isTotal ? FontWeight.bold : FontWeight
                  .normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isBold || isTotal ? FontWeight.bold : FontWeight
                  .normal,
              color: isTotal ? Colors.indigo : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}