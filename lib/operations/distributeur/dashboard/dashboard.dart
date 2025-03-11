import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swap/operations/distributeur/swap/swap%20validation/swapType.dart';

import '../history/historyDistributeur.dart';
import '../profile/profile_screen.dart';

class DashboardDistributeur extends StatefulWidget {
  final Map<String, dynamic> loggedInUser;

  const DashboardDistributeur({Key? key, required this.loggedInUser}) : super(key: key);

  @override
  _DashboardDistributeurState createState() => _DashboardDistributeurState();
}

class _DashboardDistributeurState extends State<DashboardDistributeur> {
  Map<String, dynamic>? loggedInUser;
  bool isLoading = true;

  // Color scheme
  static const Color primaryYellow = Color(0xFFDBDB35);
  static const Color darkBlue = Color(0xFF2D3250);
  static const Color lightGreen = Color(0xFFB4E197);
  static const Color offWhite = Color(0xFFF7F7F2);

  @override
  void initState() {
    super.initState();
    _loadDistributorData();
  }

  /// ✅ **Fetch Distributor Data from SharedPreferences**
  Future<void> _loadDistributorData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      loggedInUser = {
        "unique_id": prefs.getString('unique_id') ?? '',
        "name": prefs.getString('name') ?? 'Unknown User',
        "email": prefs.getString('email') ?? 'No Email',
        "phone": prefs.getString('phone') ?? 'No Phone',
        "location": prefs.getString('location') ?? 'Unknown Location',
        "userType": prefs.getString('userType') ?? '',
        "id_agence": prefs.getString('id_agence') ?? '',
        "id_entrepot": prefs.getString('id_entrepot') ?? '',
      };
      isLoading = false;
    });

    print("🚀 [DEBUG] Distributor Data Loaded: ${jsonEncode(loggedInUser)}");
  }

  /// ✅ **Show Logout Confirmation Dialog**
  Future<void> _showLogoutConfirmationDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Confirm Logout",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to log out?",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              final SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text(
              "Logout",
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ **Build Dashboard Items**
  List<Map<String, dynamic>> _buildDashboardItems(BuildContext context) {
    return [
      {
        'title': 'SWAP',
        'icon': Icons.swap_horiz,
        'color': primaryYellow,
        'gradient': [primaryYellow, Color(0xFFF2F23A)],
        'onTap': () {
          Navigator.push(context,
          MaterialPageRoute(builder: (context)=>DistributorSwapType(loggedInUser: loggedInUser!))
          );
        },
      },
      {
        'title': 'HISTORY',
        'icon': Icons.history,
        'color': lightGreen,
        'gradient': [lightGreen, Color(0xFF98C978)],
        'onTap': () {
          String? distributeurId = loggedInUser?["unique_id"];

          if (distributeurId == null || distributeurId.isEmpty) {
            print("⚠️ [WARNING] distributeur_unique_id is NULL or empty!");
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DistributeurHistoryScreen(
                distributeurUniqueId: distributeurId,
              ),
            ),
          );
        },
      },
      {
        'title': 'PROFILE',
        'icon': Icons.person,
        'color': Colors.blue,
        'gradient': [Colors.blue, Colors.lightBlueAccent],
        'onTap': () {
          String? distributeurId = widget.loggedInUser["unique_id"];

          if (distributeurId == null || distributeurId.isEmpty) {
            print("⚠️ [WARNING] distributeur_unique_id is NULL or empty!");
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DistributeurProfileScreen(profileData: loggedInUser,),
            ),
          );
        },
      },
      {
        'title': 'LOGOUT',
        'icon': Icons.logout,
        'color': Colors.redAccent,
        'gradient': [Colors.redAccent, Colors.red],
        'onTap': () => _showLogoutConfirmationDialog(),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final dashboardItems = _buildDashboardItems(context);

    return Scaffold(
      backgroundColor: offWhite,
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: primaryYellow),
      )
          : CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: primaryYellow,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                '',
                style: GoogleFonts.poppins(
                  color: darkBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome, ${loggedInUser?["name"] ?? "User"}",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkBlue,
                            ),
                          ),
                        
                          Text(
                            "${loggedInUser?["location"]}",
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
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
                  final item = dashboardItems[index];
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
                            color: item['color'].withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item['icon'],
                            color: Colors.white,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item['title'],
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: dashboardItems.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
