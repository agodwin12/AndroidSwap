import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swap/operations/agence/lease/lease%20history/lease_history.dart';
import 'package:swap/operations/agence/lease/screen/leasePayment.dart';
import 'package:swap/operations/agence/profile%20user%20agence/my_profile.dart';
import '../../authentication/login.dart';
import '../history agence/history_agence.dart';
import '../swap/battery_swap_screen.dart';

class DashboardAgence extends StatefulWidget {
  const DashboardAgence({Key? key}) : super(key: key);

  @override
  _DashboardAgenceState createState() => _DashboardAgenceState();
}

class _DashboardAgenceState extends State<DashboardAgence> {
  String? agenceId;
  String? uniqueId;
  String? email;
  String? location;
  String? userType;
  String? fullName;

  bool isLoading = true;

  // New color scheme with DCDB32 as primary
  static const Color primaryColor = Color(0xFFDCDB32);    // Gold/Yellow
  static const Color secondaryColor = Color(0xFF2D2D2D);  // Dark gray
  static const Color accentColor = Color(0xFF35383F);     // Darker shade for contrast
  static const Color backgroundColor = Color(0xFFF8F8F8); // Light background
  static const Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      agenceId = prefs.getString('id_agence') ?? 'N/A';
      uniqueId = prefs.getString('unique_id') ?? 'N/A';
      email = prefs.getString('email') ?? 'N/A';
      location = prefs.getString('location') ?? 'N/A';
      userType = prefs.getString('userType') ?? 'N/A';
      fullName = prefs.getString('name') ?? "User";
      isLoading = false;
    });

    print("🔍 [DEBUG] Loaded from SharedPreferences:");
    print("✅ agenceId: $agenceId");
    print("✅ Unique ID: $uniqueId");
    print("✅ User Name: $fullName");
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        color: backgroundColor,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      );
    }

    final List<Map<String, dynamic>> dashboardItems = [
      {
        'title': 'SWAP',
        'icon': Icons.swap_horiz_rounded,
        'color': primaryColor,
        'onTap': () {
          if (agenceId != null && agenceId!.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AgenceSwapPage(
                  agenceId: agenceId!,
                  uniqueId: uniqueId!,
                  email: email!,
                  location: location!,
                  userType: userType!,
                ),
              ),
            );
          }
        },
      },
      {
        'title': 'HISTORY',
        'icon': Icons.history_rounded,
        'color': primaryColor,
        'onTap': () {
          if (uniqueId != null && uniqueId!.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HistoryAgence(uniqueId: uniqueId ?? ''),
              ),
            );
          } else {
            print("❌ ERROR: Unique ID is missing before navigation!");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: Unique ID is missing")),
            );
          }
        },
      },
      {
        'title': 'PROFILE',
        'icon': Icons.person_rounded,
        'color': primaryColor,
        'onTap': () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen())
          );
        },
      },
      {
        'title': 'LEASE',
        'icon': Icons.payments_rounded,
        'color': primaryColor,
        'onTap': () {
          if (agenceId != null && agenceId!.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CollectPaymentScreen(
                  agenceId: agenceId!,
                  uniqueId: uniqueId!,
                  email: email!,
                  location: location!,
                  userType: userType!,
                  fullName: fullName!,
                ),
              ),
            );
          } else {
            print("❌ ERROR: Missing required data before navigating to Lease Page!");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: Missing required user data.")),
            );
          }
        },
      },
      {
        'title': 'LEASE HISTORY',
        'icon': Icons.receipt_long_rounded,
        'color': primaryColor,
        'onTap': () {
          if (agenceId != null && agenceId!.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LeaseHistoryScreen(uniqueId: uniqueId!),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: Missing agence ID")),
            );
          }
        },
      },
      {
        'title': 'LOGOUT',
        'icon': Icons.logout_rounded,
        'color': Colors.redAccent,
        'onTap': () => _showLogoutDialog(context),
      },
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Modern header with curved bottom - Responsive height
            Container(
              height: MediaQuery.of(context).size.height * 0.22,
              constraints: BoxConstraints(maxHeight: 200, minHeight: 150),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative elements
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Header content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome Back,',
                                  style: GoogleFonts.poppins(
                                    color: secondaryColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  fullName ?? 'User',
                                  style: GoogleFonts.poppins(
                                    color: secondaryColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.notifications_none_rounded,
                                color: secondaryColor,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                        // Location Card - Fixed for responsiveness
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: primaryColor,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Location',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      location ?? 'Unknown Location',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: secondaryColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 4),

                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 10),

            // Dashboard title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  Text(
                    'Dashboard',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),

            // Grid of dashboard items
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  physics: BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width < 360 ? 1 : 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: MediaQuery.of(context).size.width < 360 ? 2.5 : 1.1,
                  ),
                  itemCount: dashboardItems.length,
                  itemBuilder: (context, index) {
                    final item = dashboardItems[index];
                    final isLogout = item['title'] == 'LOGOUT';
                    return GestureDetector(
                      onTap: item['onTap'],
                      child: Container(
                        decoration: BoxDecoration(
                          color: isLogout ? Colors.red.withOpacity(0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isLogout
                                    ? Colors.red.withOpacity(0.1)
                                    : primaryColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item['icon'],
                                color: isLogout ? Colors.red : secondaryColor,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item['title'],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isLogout ? Colors.red : secondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Confirm Logout',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDCDB32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () async {
              final SharedPreferences prefs =
              await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(
                color: Color(0xFF2D2D2D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );
}