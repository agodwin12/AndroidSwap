import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../agence/dashboard/dashboard.dart';
import '../distributeur/dashboard/dashboard.dart';
import '../entrepot/dashboard/dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;

  static const Color primaryYellow = Color(0xFFDBDB35);
  static const Color darkGrey = Color(0xFF2E2E2E);
  static const Color lightGrey = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);

    final String uniqueId = _idController.text.trim();
    final String password = _passwordController.text.trim();

    if (uniqueId.isEmpty || password.isEmpty) {
      _showErrorDialog("Unique ID and password are required.");
      setState(() => _isLoading = false);
      return;
    }

    try {
      final Uri apiUrl = Uri.parse('http://10.0.2.2:3010/api/auth/login');
      final response = await http.post(
        apiUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'unique_id': uniqueId, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        await prefs.setString('token', data['token'] ?? '');
        await prefs.setString('userType', data['user']['userType'] ?? '');
        await prefs.setString('unique_id', data['user']['unique_id'] ?? '');
        await prefs.setString('name', data['user']['name'] ?? 'Unknown User');
        await prefs.setString('email', data['user']['email'] ?? 'No Email');
        await prefs.setString('phone', data['phone'] ?? '');
        await prefs.setString('location', data['user']['location'] ?? 'Unknown Location');
        await prefs.setString('id_agence', data['user']['id_agence']?.toString() ?? '');
        await prefs.setString('id_entrepot', data['user']['id_entrepot']?.toString() ?? '');

        print("✅ [DEBUG] Saved unique_id: ${prefs.getString('unique_id')}");

        String userType = data['user']['userType'] ?? '';
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Widget dashboard;
            switch (userType) {
              case "Agence":
                dashboard = const DashboardAgence();
                break;
              case "Entrepot":
                dashboard = const DashboardEntrepot();
                break;
              case "Distributeur":
                dashboard = DashboardDistributeur(loggedInUser: data['user']);
                break;
              default:
                _showErrorDialog("Invalid user type.");
                return;
            }
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => dashboard),
                  (route) => false,
            );
          });
        }
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = errorData['message'] ?? 'Login failed. Please check your credentials.';
        _showErrorDialog(errorMessage);
      }
    } catch (error) {
      _showErrorDialog("Connection error. Check your internet connection.");
    }

    setState(() => _isLoading = false);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "Login Error",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Design
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryYellow.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryYellow.withOpacity(0.1),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Logo and Title Section
                    _buildHeaderSection(),

                    const SizedBox(height: 40),

                    // Login Form
                    _buildLoginForm(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        // Lottie Animation
        SizedBox(
          height: 200,
          child: Lottie.network(
            'https://assets8.lottiefiles.com/private_files/lf30_TBKozE.json',
            height: 200,
            repeat: true,
          ),
        ),
        // Title
        Text(
          'PROXYM',
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: darkGrey,
            letterSpacing: 1.5,
          ),
        ).animate()
            .fadeIn(delay: 500.ms)
            .slideY(begin: 0.3),
        // Subtitle
        Text(
          'SWAP PORTAL',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: primaryYellow,
            letterSpacing: 1.2,
          ),
        ).animate()
            .fadeIn(delay: 800.ms)
            .slideY(begin: 0.3),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: _idController,
            hintText: 'Unique ID',
            icon: Icons.badge_outlined,
            delay: 1000,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            hintText: 'Password',
            icon: Icons.lock_outline,
            isPassword: true,
            delay: 1200,
          ),
          const SizedBox(height: 24),
          _buildLoginButton(),
        ],
      ),
    ).animate()
        .fadeIn(delay: 300.ms)
        .slideY(begin: 0.3);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    required int delay,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(color: Colors.grey),
        prefixIcon: Icon(icon, color: primaryYellow),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        )
            : null,
        filled: true,
        fillColor: lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryYellow.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryYellow, width: 2),
        ),
      ),
    ).animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .slideX(begin: 0.2);
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryYellow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: darkGrey)
            : Text(
          'Login',
          style: GoogleFonts.poppins(
            color: darkGrey,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ).animate()
        .fadeIn(delay: 1400.ms)
        .slideY(begin: 0.2);
  }
}