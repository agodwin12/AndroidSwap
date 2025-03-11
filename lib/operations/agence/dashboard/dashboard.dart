import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
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

  //  color
  static const Color primaryColor = Color(0xFF6C63FF);    // Modern purple
  static const Color secondaryColor = Color(0xFF2A2D3E);  // Dark blue-grey
  static const Color accentColor = Color(0xFF00D9F5);     // Cyan
  static const Color backgroundColor = Color(0xFFF5F7FF); // Light blue-grey
  static const Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      agenceId = prefs.getString('id_agence') ?? 'N/A'; // ✅ Keep id_agence as is
      uniqueId = prefs.getString('unique_id') ?? 'N/A'; // ✅ Keep unique_id as is
      email = prefs.getString('email') ?? 'N/A';
      location = prefs.getString('location') ?? 'N/A';
      userType = prefs.getString('userType') ?? 'N/A';

      // ✅ Store full name separately
      fullName = prefs.getString('name') ?? "User"; // ✅ Corrected fullName usage

      isLoading = false;
    });

    print("🔍 [DEBUG] Loaded from SharedPreferences:");
    print("✅ agenceId: $agenceId");
    print("✅ Unique ID: $uniqueId"); // ✅ Now keeps uniqueId unchanged
    print("✅ User Name: $fullName"); // ✅ New fullName for display
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
        'icon': Icons.swap_horiz,
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
        'icon': Icons.history,
        'color': accentColor,
        'onTap': () {
          if (uniqueId != null && uniqueId!.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HistoryAgence(uniqueId: uniqueId ?? ''), // ✅ Ensure non-null
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
        'icon': Icons.person,
        'color': secondaryColor,
        'onTap': () {
          Navigator.push(
            context,
          MaterialPageRoute(builder:
          (context)=>ProfileScreen()
          )
          );

        },
      },
      {
        'title': 'LOGOUT',
        'icon': Icons.logout,
        'color': Colors.redAccent,
        'onTap': () => _showLogoutDialog(context),
      },
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Column(
          children: [
            Text(
              'Welcome Back!',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            Text(
              fullName ?? 'User',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ],
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: primaryColor.withOpacity(0.1),
                      radius: 24,
                      child: Icon(
                        Icons.location_on,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
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
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: dashboardItems.length,
                  itemBuilder: (context, index) {
                    final item = dashboardItems[index];
                    return GestureDetector(
                      onTap: item['onTap'],
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: item['color'].withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item['icon'],
                                color: item['color'],
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item['title'],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: secondaryColor,
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
          borderRadius: BorderRadius.circular(16),
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
          TextButton(
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
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );
}