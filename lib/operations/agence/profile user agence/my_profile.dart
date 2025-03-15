import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

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

    final String apiUrl = "http://10.0.2.2:3010/api/user-agence/$uniqueId";
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
            "user_agence_unique_id": data["user"]["user_agence_unique_id"] ?? "",
            "id_agence": data["user"]["id_agence"]?.toString() ?? "",
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
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue.shade800,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // ✅ Navigate back
          },
        ),
      ),
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
    return SingleChildScrollView( // ✅ Makes page scrollable
      physics: const BouncingScrollPhysics(), // ✅ Smooth scrolling
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Personal Details',
              [
                _buildInfoTile(Icons.account_circle, 'Full Names', '${userData!['nom']} ${userData!['prenom']}'),
                _buildInfoTile(Icons.email, 'Email', userData!['email']),
                _buildInfoTile(Icons.phone, 'Phone', userData!['phone']),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Location',
              [
                _buildInfoTile(Icons.location_city, 'Ville', userData!['ville']),
                _buildInfoTile(Icons.place, 'Quartier', userData!['quartier']),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Account Information',
              [
                _buildInfoTile(Icons.numbers, 'ID Unique', userData!['user_agence_unique_id']),
                _buildInfoTile(Icons.store, 'ID Agence', userData!['id_agence']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
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
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade800),
      title: Text(label, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
      subtitle: Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }
}
