// Model for Driver data
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Driver {
  final String id;
  final String name;
  final String phoneNumber;
  final String vehicleNumber;
  final double pendingAmount;

  Driver({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.vehicleNumber,
    this.pendingAmount = 0.0,
  });
}

// Static list of drivers for demonstration
final List<Driver> driversData = [
  Driver(
    id: "DRV001",
    name: "John Smith",
    phoneNumber: "0123456789",
    vehicleNumber: "KA01AB1234",
    pendingAmount: 500.0,
  ),
  Driver(
    id: "DRV002",
    name: "Sarah Johnson",
    phoneNumber: "9876543210",
    vehicleNumber: "KA02CD5678",
    pendingAmount: 750.0,
  ),
  Driver(
    id: "DRV003",
    name: "Michael Brown",
    phoneNumber: "7890123456",
    vehicleNumber: "KA03EF9012",
    pendingAmount: 0.0,
  ),
  Driver(
    id: "DRV004",
    name: "Emily Davis",
    phoneNumber: "4567890123",
    vehicleNumber: "KA04GH3456",
    pendingAmount: 1200.0,
  ),
  Driver(
    id: "DRV005",
    name: "David Wilson",
    phoneNumber: "3210987654",
    vehicleNumber: "KA05IJ7890",
    pendingAmount: 300.0,
  ),
  Driver(
    id: "DRV006",
    name: "Lisa Martinez",
    phoneNumber: "6543210987",
    vehicleNumber: "KA06KL1234",
    pendingAmount: 850.0,
  ),
  Driver(
    id: "DRV007",
    name: "Robert Taylor",
    phoneNumber: "8901234567",
    vehicleNumber: "KA07MN5678",
    pendingAmount: 0.0,
  ),
  Driver(
    id: "DRV008",
    name: "Jennifer Anderson",
    phoneNumber: "2345678901",
    vehicleNumber: "KA08OP9012",
    pendingAmount: 600.0,
  ),
  Driver(
    id: "DRV009",
    name: "William Thomas",
    phoneNumber: "5678901234",
    vehicleNumber: "KA09QR3456",
    pendingAmount: 420.0,
  ),
  Driver(
    id: "DRV010",
    name: "Jessica Garcia",
    phoneNumber: "7654321098",
    vehicleNumber: "KA10ST7890",
    pendingAmount: 950.0,
  ),
];

// Theme colors for the app
class AppColors {
  static const Color primaryYellow = Color(0xFFFFC107);
  static const Color primaryYellowDark = Color(0xFFFFA000);
  static const Color accentColor = Color(0xFF212121);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color background = Color(0xFFFAFAFA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color successGreen = Color(0xFF388E3C);
}

// Main theme for the app
final ThemeData appTheme = ThemeData(
  primaryColor: AppColors.primaryYellow,
  primaryColorDark: AppColors.primaryYellowDark,
  hintColor: AppColors.accentColor,
  fontFamily: 'Poppins',
  textTheme: TextTheme(
    displayLarge: TextStyle(
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    displayMedium: TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 16.0,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14.0,
      color: AppColors.textSecondary,
    ),
    labelLarge: TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: AppColors.accentColor,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: AppColors.accentColor, backgroundColor: AppColors.primaryYellow,
      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: AppColors.primaryYellow, width: 2.0),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: AppColors.errorRed, width: 1.0),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
  ),
  cardTheme: CardTheme(
    elevation: 2.0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
    color: AppColors.cardBackground,
  ),
);