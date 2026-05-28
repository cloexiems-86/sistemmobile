import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/login_page.dart';
import 'edit_profil_page.dart';
import 'pusat_bantuan_page.dart';
import 'syarat_ketentuan_page.dart';

class ProfilPendampingPage extends StatefulWidget {
  final Map userData;

  const ProfilPendampingPage({super.key, required this.userData});

  @override
  State<ProfilPendampingPage> createState() => _ProfilPendampingPageState();
}

class _ProfilPendampingPageState extends State<ProfilPendampingPage> {
  bool _notifikasiAktif = true;
  late Map _userData = widget.userData;

  @override
  void initState() {
    super.initState();
    _userData = widget.userData;
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Keluar", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Apakah Anda yakin ingin keluar dari aplikasi?", style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDummyFeatureMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur ini akan segera hadir')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String nama = _userData['nama'] ?? 'Pendamping';
    final String nip = _userData['nip'] ?? _userData['username'] ?? 'NIP tidak tersedia';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context, _userData),
        ),
        title: Text("Profil & Pengaturan", style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Profile Info
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE8F5E9),
                      border: Border.all(color: const Color(0xFF19e62b).withOpacity(0.3), width: 4),
                    ),
                    child: const Icon(Icons.person, size: 60, color: Color(0xFF19e62b)),
                  ),
                  const SizedBox(height: 16),
                  Text(nama, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(
                    nip.startsWith('NIP') ? nip : "NIP: $nip",
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Pengaturan Akun
            Align(
              alignment: Alignment.centerLeft,
              child: Text("PENGATURAN AKUN", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.2)),
            ),
            const SizedBox(height: 16),
            _buildSettingsMenu(
              icon: Icons.person,
              title: "Edit Profil",
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfilPage(userData: _userData)),
                );
                if (result != null && result is Map) {
                  setState(() {
                    _userData = result;
                  });
                }
              },
            ),
            _buildSettingsMenu(
              icon: Icons.notifications,
              title: "Notifikasi",
              isToggle: true,
              toggleValue: _notifikasiAktif,
              onToggle: (value) {
                setState(() {
                  _notifikasiAktif = value;
                });
              },
            ),

            const SizedBox(height: 24),

            // Dukungan
            Align(
              alignment: Alignment.centerLeft,
              child: Text("DUKUNGAN", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.2)),
            ),
            const SizedBox(height: 16),
            _buildSettingsMenu(
              icon: Icons.help,
              title: "Pusat Bantuan",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PusatBantuanPage()),
                );
              },
            ),
            _buildSettingsMenu(
              icon: Icons.description,
              title: "Syarat & Ketentuan",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SyaratKetentuanPage()),
                );
              },
            ),

            const SizedBox(height: 40),

            // Keluar Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                label: Text("Keluar", style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Versi
            Text("Versi 2.4.0 (Build 102)", style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400])),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsMenu({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    bool isToggle = false,
    bool toggleValue = false,
    Function(bool)? onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: isToggle ? null : onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        trailing: isToggle
            ? Switch(
                value: toggleValue,
                onChanged: onToggle,
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF19e62b),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey[300],
              )
            : const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      ),
    );
  }
}
