import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swap/operations/authentication/login.dart';
import 'package:swap/operations/entrepot/history/historyentrepot.dart';
import 'package:swap/operations/entrepot/swap%20screen/swap%20type/swap_type.dart';

import '../profile user/my_profile.dart';

class DashboardEntrepot extends StatefulWidget {
  const DashboardEntrepot({Key? key}) : super(key: key);

  @override
  _DashboardEntrepotState createState() => _DashboardEntrepotState();
}

class _DashboardEntrepotState extends State<DashboardEntrepot> {
  Map<String, dynamic>? loggedInUser;

  // Color scheme
  static const Color primaryYellow = Color(0xFFDBDB35);
  static const Color darkGrey = Color(0xFF2E2E2E);
  static const Color lightGrey = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      loggedInUser = {
        "name": prefs.getString("name") ?? "Unknown",
        "location": prefs.getString("location") ?? "Unknown Location",
        "userType": prefs.getString("userType") ?? "Unknown",
        "unique_id": prefs.getString("unique_id") ?? "Unknown ID",
        "id_agence": prefs.getString("id_agence") ?? "",
        "id_entrepot": prefs.getString("id_entrepot") ?? "",
      };
    });

    if (loggedInUser!["name"] == "Unknown") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  List<Map<String, dynamic>> getDashboardItems() {
    return [
      {
        'title': 'SWAP',
        'icon': Icons.swap_horiz,
        'description': 'Manage battery swaps',
        'gradient': [primaryYellow, Color(0xFFE6E635)],
        'onTap': () {
          if (loggedInUser != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SwapType(loggedInUser: loggedInUser!),
              ),
            );
          } else {
            _showErrorDialog("User data not loaded. Please log in again.");
          }
        },
      },
      {
        'title': 'HISTORY',
        'icon': Icons.history,
        'description': 'View past transactions',
        'gradient': [Color(0xFF4A4A4A), Color(0xFF606060)],
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserSwapHistory()),
          );

        },
      },
      {
        'title': 'PROFILE',
        'icon': Icons.person,
        'description': 'Manage your account',
        'gradient': [Color(0xFF3D3D3D), Color(0xFF4F4F4F)],
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userData: loggedInUser!),
            ),
          );
        },
      },
      {
        'title': 'LOGOUT',
        'icon': Icons.logout,
        'description': 'Exit your account',
        'gradient': [Colors.redAccent, Colors.red],
        'onTap': () => _showLogoutDialog(context),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGrey,
      body: loggedInUser == null
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
        ),
      )
          : CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: primaryYellow,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.all(16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loggedInUser!["name"],
                    style: GoogleFonts.poppins(
                      color: darkGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    loggedInUser!["location"],
                    style: GoogleFonts.poppins(
                      color: darkGrey.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          primaryYellow,
                          primaryYellow.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -100,
                    top: -100,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final item = getDashboardItems()[index];
                  return GestureDetector(
                    onTap: item['onTap'],
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: item['gradient'],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: item['gradient'][0].withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -30,
                            bottom: -30,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    item['icon'],
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  item['title'],
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['description'],
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: getDashboardItems().length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Confirm Logout',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
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
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async => await _logout(context),
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

  Future<void> _logout(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await Future.delayed(const Duration(milliseconds: 500));
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          "Error",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: GoogleFonts.poppins(color: primaryYellow),
            ),
          ),
        ],
      ),
    );
  }
}