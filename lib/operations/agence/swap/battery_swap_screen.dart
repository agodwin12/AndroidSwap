import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class AgenceSwapPage extends StatefulWidget {
  final String agenceId;
  final String uniqueId;
  final String email;
  final String location;
  final String userType;

  const AgenceSwapPage({
    required this.agenceId,
    required this.uniqueId,
    required this.email,
    required this.location,
    required this.userType,
    Key? key,
  }) : super(key: key);

  @override
  _AgenceSwapPageState createState() => _AgenceSwapPageState();
}

class _AgenceSwapPageState extends State<AgenceSwapPage> {
  List<Map<String, dynamic>> outgoingBatteries = [];
  List<Map<String, dynamic>> filteredBatteries = [];
  String? selectedOutgoingBattery;
  double? outgoingSOC;
  bool isFetchingOutgoingSOC = false;
  TextEditingController incomingBatteryController = TextEditingController();
  double? incomingSOC;
  bool isFetchingIncomingSOC = false;
  double? swapPrice;
  bool isValidatingSwap = false;
  Map<String, dynamic> incomingUser = {};
  bool showSuccessAnimation = false;
  bool showErrorAnimation = false;

  @override
  void initState() {
    super.initState();
    fetchOutgoingBatteries();
  }

  void resetAndRefresh() {
    setState(() {
      selectedOutgoingBattery = null;
      outgoingSOC = null;
      incomingBatteryController.clear();
      incomingSOC = null;
      swapPrice = null;
      incomingUser = {};
      showSuccessAnimation = false;
      showErrorAnimation = false;
    });
    fetchOutgoingBatteries();
  }

  void showSuccess() {
    setState(() {
      showSuccessAnimation = true;
      showErrorAnimation = false;
    });
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        resetAndRefresh();
      }
    });
  }

  void showError() {
    setState(() {
      showErrorAnimation = true;
      showSuccessAnimation = false;
    });
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          showErrorAnimation = false;
        });
      }
    });
  }

  void filterBatteries(String query) {
    setState(() {
      filteredBatteries = outgoingBatteries
          .where((battery) => battery["mac_id"]
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> fetchOutgoingBatteries() async {
    final url = "http://10.0.2.2:3010/api/agenceswapbatteries/${widget.agenceId}";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data["success"] == true) {
          setState(() {
            outgoingBatteries = List<Map<String, dynamic>>.from(data["batteries"]);
            filteredBatteries = outgoingBatteries;
          });
        }
      }
    } catch (error) {
      print("❌ [ERROR] Exception while fetching batteries: $error");
    }
  }

  Future<void> fetchOutgoingSOC(String macId) async {
    setState(() {
      isFetchingOutgoingSOC = true;
    });

    final url = "http://10.0.2.2:3010/api/batteries/soc/$macId";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          outgoingSOC = data["SOC"] != null
              ? double.parse(data["SOC"].toString().replaceAll("%", ""))
              : null;
          isFetchingOutgoingSOC = false;
        });
        calculateSwapPrice();
      }
    } catch (error) {
      print("❌ Error fetching outgoing SOC: $error");
      setState(() {
        isFetchingOutgoingSOC = false;
      });
    }
  }

  Future<void> fetchBatteryDetailsAndPrice(String macId, double outgoingSOC) async {
    setState(() {
      isFetchingIncomingSOC = true;
    });

    final url = "http://10.0.2.2:3010/api/battery/details";
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "mac_id": macId,
          "outgoingSOC": outgoingSOC,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          incomingSOC = data["incomingSOC"] != null
              ? double.parse(data["incomingSOC"].toString().replaceAll("%", ""))
              : null;
          incomingUser = data["user"] ?? {};
          swapPrice = data["swapPrice"] != null
              ? double.tryParse(data["swapPrice"].toString())
              : 0;
          isFetchingIncomingSOC = false;
        });
      }
    } catch (error) {
      print("❌ Error fetching battery details: $error");
      setState(() {
        isFetchingIncomingSOC = false;
      });
    }
  }


  int roundUpToNearest50(double value) {
    return ((value / 50).ceil() * 50).toInt();
  }

  // This function transforms the SOC value using the provided formula
  int transformSOC(double socDbValue) {
    return ((socDbValue - 7) * 100 / (100 - 7)).clamp(0, 100).toInt();
  }


  void calculateSwapPrice() {
    if (outgoingSOC != null && incomingSOC != null) {
      setState(() {
        // Calculate the price, then round up to nearest 50
        double rawPrice = (outgoingSOC! - incomingSOC! > 0)
            ? ((outgoingSOC! - incomingSOC!) * 2000) / 93
            : 0;
        swapPrice = roundUpToNearest50(rawPrice).toDouble();
      });
    }
  }


// 1. First, let's update the validateSwap() method to show the confirmation dialog

  Future<void> validateSwap() async {
    if (selectedOutgoingBattery == null || incomingBatteryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both batteries')),
      );
      return;
    }

    if (swapPrice == null || swapPrice! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid swap: Outgoing battery SOC must be higher than incoming battery SOC')),
      );
      return;
    }

    // Show confirmation dialog first
    _showConfirmationDialog();
  }

// 2. Add a method to show the confirmation dialog
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF233554),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Confirm Swap Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Information',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFDBDB35),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildConfirmationDetail('Name', '${incomingUser["nom"]} ${incomingUser["prenom"]}'),
              _buildConfirmationDetail('Phone', '${incomingUser["phone"]}'),
              const Divider(color: Colors.white24),

              Text(
                'Battery Information',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFDBDB35),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildConfirmationDetail('Outgoing Battery', selectedOutgoingBattery ?? 'N/A'),
              _buildConfirmationDetail('Outgoing SOC', '${transformSOC(outgoingSOC!)}%'),
              _buildConfirmationDetail('Incoming Battery', '61388162${incomingBatteryController.text}'),
              _buildConfirmationDetail('Incoming SOC', '${transformSOC(incomingSOC!)}%'),
              const Divider(color: Colors.white24),

              Text(
                'Swap Details',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFDBDB35),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildConfirmationDetail('SOC Difference', '${(transformSOC(outgoingSOC!) - transformSOC(incomingSOC!)).abs()}%'),
              _buildConfirmationDetail('Swap Price', 'XAF ${swapPrice?.toInt() ?? 0}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.white70,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDBDB35),
              foregroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showPaymentConfirmation();
            },
            child: Text(
              'Proceed',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

// 3. Add a method to ask for payment confirmation
  void _showPaymentConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF233554),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Payment Confirmation',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.payment,
              color: const Color(0xFFDBDB35),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Has the customer paid XAF ${swapPrice?.toInt() ?? 0}?',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.white70,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDBDB35),
              foregroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _processSwap();
            },
            child: Text(
              'Payment Received',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

// 4. Add a method to process the actual swap after confirmation
  Future<void> _processSwap() async {
    setState(() {
      isValidatingSwap = true;
    });

    try {
      final requestData = {
        'battery_in_mac_id': '61388162${incomingBatteryController.text}',
        'battery_out_mac_id': selectedOutgoingBattery,
        'user_agence_unique_id': widget.uniqueId,
        'swap_price': swapPrice?.toInt() ?? 0,
      };

      final response = await http.post(
        Uri.parse('http://10.0.2.2:3010/api/swap'),
        body: json.encode(requestData),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        showSuccess();
      } else {
        showError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.body)),
        );
      }
    } catch (error) {
      showError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing swap: $error')),
      );
    } finally {
      setState(() {
        isValidatingSwap = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF233554),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          'Battery Swap',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOutgoingBatterySection(),
                            const SizedBox(height: 20),
                            if (selectedOutgoingBattery != null)
                              _buildSelectedBatteryDisplay(),
                            const SizedBox(height: 20),
                            _buildIncomingBatterySection(),
                            const SizedBox(height: 20),
                            if (selectedOutgoingBattery != null && incomingSOC != null)
                              _buildSwapValidationSection(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showSuccessAnimation)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/Success.json',
                      width: 200,
                      height: 200,
                      repeat: false,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Swap Successful!',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (showErrorAnimation)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/error (2).json',
                      width: 200,
                      height: 200,
                      repeat: false,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Swap Failed!',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOutgoingBatterySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Outgoing Battery',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search batteries...',
            hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.5)),
            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: const Color(0xFF233554),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: filterBatteries,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF233554),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredBatteries.length,
            itemBuilder: (context, index) {
              final battery = filteredBatteries[index];
              final isSelected = selectedOutgoingBattery == battery["mac_id"];
              return _buildBatteryItem(battery, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBatteryItem(Map<String, dynamic> battery, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedOutgoingBattery = null;
            outgoingSOC = null;
          } else {
            selectedOutgoingBattery = battery["mac_id"];
            fetchOutgoingSOC(battery["mac_id"]);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDBDB35).withOpacity(0.3) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFFDBDB35) : Colors.white.withOpacity(0.6),
            ),
            const SizedBox(width: 10),
            Text(
              battery["mac_id"],
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedBatteryDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF233554),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBDB35).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Outgoing Battery',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedOutgoingBattery ?? '',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFDBDB35),
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  Text(
                    'SOC: ',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  if (isFetchingOutgoingSOC)
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFDBDB35),
                      ),
                    )
                  else
                    Text(
                      outgoingSOC != null ? '${transformSOC(outgoingSOC!)}%' : 'N/A',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFDBDB35),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildIncomingBatterySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF233554),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Incoming Battery',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: incomingBatteryController,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter battery MAC ID...',
              hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              if (value.length == 4) {
                fetchBatteryDetailsAndPrice(
                  '61388162$value',
                  outgoingSOC ?? 0,
                );
              }
            },
          ),
          if (incomingSOC != null || isFetchingIncomingSOC)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Battery Charge:',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  if (isFetchingIncomingSOC)
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFDBDB35),
                      ),
                    )
                  else
                    Text(
                      '${transformSOC(incomingSOC!)}%',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFDBDB35),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          if (incomingUser.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Battery Owner:',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${incomingUser["nom"]} ${incomingUser["prenom"]}',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFDBDB35),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phone: ${incomingUser["phone"]}',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFDBDB35),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwapValidationSection() {
    bool isSwapValid = (swapPrice != null && swapPrice! > 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF233554),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBDB35).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Swap Details',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            title: 'SOC Difference:',
            value: (outgoingSOC != null && incomingSOC != null)
                ? '${(transformSOC(outgoingSOC!) - transformSOC(incomingSOC!)).abs()}%'
                : 'N/A',
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            title: 'Swap Price:',
            value: 'XAF ${swapPrice?.toInt() ?? 0}',
          ),
          if (!isSwapValid)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Invalid swap: Outgoing battery SOC must be higher than incoming battery SOC',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isValidatingSwap || !isSwapValid ? null : validateSwap,
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color(0xFF1A1A2E),
                backgroundColor: isSwapValid ? const Color(0xFFDBDB35) : Colors.grey,
                disabledForegroundColor: Colors.grey.shade700,
                disabledBackgroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isValidatingSwap
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1A1A2E),
                ),
              )
                  : Text(
                isSwapValid ? 'Validate Swap' : 'Invalid Swap',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDetailRow({required String title, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: const Color(0xFFDBDB35),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    incomingBatteryController.dispose();
    super.dispose();
  }
}