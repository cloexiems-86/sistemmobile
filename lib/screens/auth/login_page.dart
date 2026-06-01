import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../catin/home_page.dart';
import '../pendamping/dashboard_pendamping.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String _currentIp = 'farel.dwirez.app';

  @override
  void initState() {
    super.initState();
    _loadIp();
  }

  Future<void> _loadIp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIp = prefs.getString('api_ip') ?? 'farel.dwirez.app';
    });
  }

  Future<void> loginProses() async {
    if (_isLoading) return;

    final username = _userController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar("Harap isi username dan password!");
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse("https://$_currentIp/catin_api/login.php");
      final response = await http.post(
        url,
        headers: {"Accept": "application/json"},
        body: {"username": username, "password": password},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          _showSnackBar("Selamat Datang, ${data['user']['nama']}");
          if (data['user']['role'] == 'catin') {
            _showPilihProfil(data['user']);
          } else if (data['user']['role'] == 'pendamping') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPendamping(userData: data['user'])),
            );
          } else {
            _showSnackBar("Role tidak dikenali");
          }
        } else {
          _showSnackBar(data['message'] ?? 'Login gagal');
        }
      } else if (response.statusCode == 401) {
        final data = jsonDecode(response.body);
        _showSnackBar(data['message'] ?? "Username atau Password salah.");
      } else {
        _showSnackBar("Gagal login. Status: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Gagal terhubung ke server. Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPilihProfil(Map userData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          "Siapa yang akan belajar?",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.male,
                color: Colors.blue,
              ),
              title: Text(
                userData['nama_suami'] ?? 'Calon Suami',
                style: GoogleFonts.poppins(),
              ),
              onTap: () => _masukDashboard(
                userData,
                userData['nama_suami'] ?? '',
                'suami',
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.female,
                color: Colors.pink,
              ),
              title: Text(
                userData['nama_istri'] ?? 'Calon Istri',
                style: GoogleFonts.poppins(),
              ),
              onTap: () => _masukDashboard(
                userData,
                userData['nama_istri'] ?? '',
                'istri',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _masukDashboard(
    Map userData,
    String namaAktif,
    String peserta,
  ) {
    userData['nama_aktif'] = namaAktif;
    userData['peserta'] = peserta;

    Navigator.pop(context);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(userData: userData),
      ),
    );
  }

  void _showSnackBar(String pesan) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan, style: GoogleFonts.poppins())));
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF19e62b);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 30),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          "E-Learning KUA",
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
        child: Column(
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B1E), // Dark circle background like in the image
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              padding: const EdgeInsets.all(15),
              child: Image.asset(
                'assets/logo_kua.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance, color: primaryColor, size: 60),
              ),
            ),
            const SizedBox(height: 24),
            // Headings
            Text(
              "Bimbingan Perkawinan",
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              "Silakan masuk menggunakan akun yang telah diberikan oleh petugas KUA",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 40),
            // Username Field
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Username", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _userController,
              hint: "Masukkan username Anda",
              icon: Icons.person,
            ),
            const SizedBox(height: 20),
            // Password Field
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Kata Sandi", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _passwordController,
              hint: "Masukkan kata sandi",
              icon: Icons.remove_red_eye,
              isPassword: true,
            ),
            const SizedBox(height: 12),
            // Forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Lupa Kata Sandi?",
                style: GoogleFonts.poppins(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const SizedBox(height: 32),
            // Login Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : loginProses,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Masuk", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 8),
                          const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 80),
            // Footer
            Text(
              "Belum punya akun?",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              "Hubungi Kantor Urusan Agama (KUA) setempat untuk mendapatkan kredensial akses.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
          prefixIcon: isPassword ? null : Icon(icon, color: Colors.grey[400], size: 22),
          suffixIcon: isPassword 
              ? IconButton(
                  icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey[400]),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              : Icon(icon, color: Colors.grey[400], size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}