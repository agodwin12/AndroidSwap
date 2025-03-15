import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key, required Map<String, dynamic> userData}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uniqueId = prefs.getString("unique_id");

    if (uniqueId == null || uniqueId.isEmpty) {
      setState(() {
        errorMessage = "No Unique ID found. Please log in again.";
        isLoading = false;
      });
      return;
    }

    final String apiUrl = "http://10.0.2.2:3010/api/users-entrepot/$uniqueId";
    print("🔍 Fetching user profile from: $apiUrl");

    try {
      final response = await http.get(Uri.parse(apiUrl));

      print("🔍 Response status: ${response.statusCode}");
      print("🔍 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          userData = {
            "nom": data["user"]["nom"] ?? "",
            "prenom": data["user"]["prenom"] ?? "",
            "email": data["user"]["email"] ?? "",
            "phone": data["user"]["phone"] ?? "",
            "ville": data["user"]["ville"] ?? "",
            "quartier": data["user"]["quartier"] ?? "",
            "users_entrepot_unique_id": data["user"]["users_entrepot_unique_id"] ?? "",
            "id_entrepot": data["user"]["id_entrepot"]?.toString() ?? "",
            "photo": data["user"]["photo"] ?? "",
          };
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load profile. Status: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = "Error fetching profile: $error";
        isLoading = false;
      });
      print("❌ [ERROR] Fetching profile failed: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
        child: Text(
          errorMessage,
          style: const TextStyle(color: Colors.red),
        ),
      )
          : _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200.0,
          floating: false,
          pinned: true,
          backgroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'MY ACCOUNT',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.blue.shade800,
                    Colors.blue.shade600,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 60,
                    left: 20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          getInitials(userData!['nom'], userData!['prenom']),
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  'Personal Details',
                  [
                    _buildInfoTile('account_circle', 'Full Names', '${userData!['nom']} ${userData!['prenom']}'),
                    _buildInfoTile('email', 'Email', userData!['email']),
                    _buildInfoTile('phone', 'Phone', userData!['phone']),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Location',
                  [
                    _buildInfoTile('location_city', 'Ville', userData!['ville']),
                    _buildInfoTile('place', 'Quartier', userData!['quartier']),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Informations du Compte',
                  [
                    _buildInfoTile('numbers', 'ID Unique', userData!['users_entrepot_unique_id']),
                    _buildInfoTile('store', 'ID Entrepôt', userData!['id_entrepot'].toString()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String icon, String label, String value) {
    return ListTile(
      leading: Icon(
        Icons.person,
        color: Colors.blue.shade800,
      ),
      title: Text(label, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
      subtitle: Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }

  String getInitials(String nom, String prenom) {
    return '${nom[0]}${prenom[0]}'.toUpperCase();
  }
}
