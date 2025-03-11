import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../model/model.dart';

class CollectPaymentScreen extends StatefulWidget {
  const CollectPaymentScreen({Key? key}) : super(key: key);

  @override
  _CollectPaymentScreenState createState() => _CollectPaymentScreenState();
}

class _CollectPaymentScreenState extends State<CollectPaymentScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _leaseAmountController = TextEditingController();
  final TextEditingController _batteryCautionController = TextEditingController();

  Driver? selectedDriver;
  List<Driver> filteredDrivers = [];
  bool showDriversList = false;

  @override
  void initState() {
    super.initState();
    filteredDrivers = List.from(driversData);
  }

  void filterDrivers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredDrivers = List.from(driversData);
      } else {
        filteredDrivers = driversData
            .where((driver) =>
        driver.name.toLowerCase().contains(query.toLowerCase()) ||
            driver.phoneNumber.contains(query))
            .toList();
      }
      showDriversList = true;
    });
  }

  void selectDriver(Driver driver) {
    setState(() {
      selectedDriver = driver;
      _searchController.text = driver.name;
      showDriversList = false;
    });
  }

  void showConfirmationDialog() {
    if (selectedDriver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a driver"),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (_leaseAmountController.text.isEmpty || _batteryCautionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter all payment details"),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    double leaseAmount = double.tryParse(_leaseAmountController.text) ?? 0.0;
    double batteryCaution = double.tryParse(_batteryCautionController.text) ?? 0.0;
    double totalAmount = leaseAmount + batteryCaution;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Confirm Payment",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PaymentInfoRow(
              icon: FontAwesomeIcons.user,
              label: "Driver",
              value: selectedDriver!.name,
            ),
            SizedBox(height: 12),
            PaymentInfoRow(
              icon: FontAwesomeIcons.phone,
              label: "Phone",
              value: selectedDriver!.phoneNumber,
            ),
            SizedBox(height: 12),
            PaymentInfoRow(
              icon: FontAwesomeIcons.moneyBill,
              label: "Lease Amount",
              value: "\$${leaseAmount.toStringAsFixed(2)}",
            ),
            SizedBox(height: 12),
            PaymentInfoRow(
              icon: FontAwesomeIcons.batteryHalf,
              label: "Battery Caution",
              value: "\$${batteryCaution.toStringAsFixed(2)}",
            ),
            Divider(height: 24),
            PaymentInfoRow(
              icon: FontAwesomeIcons.solidCreditCard,
              label: "Total",
              value: "\$${totalAmount.toStringAsFixed(2)}",
              isTotal: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "No",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showReceiptConfirmationDialog(totalAmount);
            },
            child: Text(
              "Yes",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void showReceiptConfirmationDialog(double totalAmount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Payment Confirmation",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FontAwesomeIcons.moneyCheckDollar,
              size: 48,
              color: AppColors.primaryYellow,
            ),
            SizedBox(height: 16),
            Text(
              "Did you receive the money?",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "\$${totalAmount.toStringAsFixed(2)}",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.accentColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Here you would handle the payment confirmation
              // For now, we'll just show a success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Payment successful!"),
                  backgroundColor: AppColors.successGreen,
                ),
              );

              // Reset the form
              setState(() {
                selectedDriver = null;
                _searchController.clear();
                _leaseAmountController.clear();
                _batteryCautionController.clear();
              });
            },
            child: Text(
              "Confirm",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryYellow,
        title: Text(
          "Collect Payments",
          style: TextStyle(
            color: AppColors.accentColor,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            setState(() {
              showDriversList = false;
            });
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search for driver
                Text(
                  "Search Driver",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search by name or phone number",
                      prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            filteredDrivers = List.from(driversData);
                            selectedDriver = null;
                            showDriversList = false;
                          });
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      filterDrivers(value);
                    },
                    onTap: () {
                      setState(() {
                        showDriversList = true;
                      });
                    },
                  ),
                ),

                // Drivers list
                if (showDriversList && filteredDrivers.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredDrivers.length,
                      itemBuilder: (context, index) {
                        final driver = filteredDrivers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryYellow,
                            child: Text(
                              driver.name[0],
                              style: TextStyle(
                                color: AppColors.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            driver.name,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            driver.phoneNumber,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => selectDriver(driver),
                        );
                      },
                    ),
                  ),

                SizedBox(height: 24),

                // Driver details card (if selected)
                if (selectedDriver != null)
                  Card(
                    margin: EdgeInsets.only(bottom: 24),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primaryYellow,
                                child: Text(
                                  selectedDriver!.name[0],
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: AppColors.accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedDriver!.name,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      selectedDriver!.phoneNumber,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Vehicle",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      selectedDriver!.vehicleNumber,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Pending Amount",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      "\$${selectedDriver!.pendingAmount.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                        color: selectedDriver!.pendingAmount > 0
                                            ? AppColors.errorRed
                                            : AppColors.successGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Lease amount input
                Text(
                  "Lease Amount",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _leaseAmountController,
                  decoration: InputDecoration(
                    hintText: "Enter lease amount",
                    prefixIcon: Icon(FontAwesomeIcons.dollarSign, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),

                SizedBox(height: 24),

                // Battery caution input
                Text(
                  "Battery Caution",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _batteryCautionController,
                  decoration: InputDecoration(
                    hintText: "Enter battery caution amount",
                    prefixIcon: Icon(FontAwesomeIcons.batteryHalf, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),

                SizedBox(height: 32),

                // Pay lease button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: showConfirmationDialog,
                    icon: Icon(FontAwesomeIcons.moneyBillTransfer),
                    label: Text(
                      "Pay Lease",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: AppColors.accentColor, backgroundColor: AppColors.primaryYellow,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _leaseAmountController.dispose();
    _batteryCautionController.dispose();
    super.dispose();
  }
}

// Helper widget for payment info rows in the dialog
class PaymentInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isTotal;

  const PaymentInfoRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    this.isTotal = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isTotal ? AppColors.primaryYellow : AppColors.textSecondary,
        ),
        SizedBox(width: 8),
        Text(
          "$label:",
          style: TextStyle(
            fontFamily: 'Poppins',
            color: AppColors.textSecondary,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 18 : 14,
            color: isTotal ? AppColors.accentColor : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}