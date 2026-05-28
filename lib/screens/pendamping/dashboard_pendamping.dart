import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../catin/materi_page.dart';
import '../auth/login_page.dart';
import 'daftar_peserta_page.dart';
import 'profil_pendamping_page.dart';
import 'notifikasi_page.dart';
import '../catin/jadwal_page.dart';

class DashboardPendamping extends StatefulWidget {
  final Map userData;
  const DashboardPendamping({super.key, required this.userData});

  @override
  State<DashboardPendamping> createState() => _DashboardPendampingState();
}

class _DashboardPendampingState extends State<DashboardPendamping> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _notifikasiList = [];
  String _currentIp = 'farel.dwirez.app';
  int _currentIndex = 0; // for bottom nav
  late Map _userData = widget.userData;

  @override
  void initState() {
    super.initState();
    _userData = widget.userData;
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIp = prefs.getString('api_ip') ?? 'farel.dwirez.app';
      _isLoading = true;
    });
    
    try {
      final pendampingId = _userData['id'];
      
      final url = Uri.parse("https://$_currentIp/pendamping_api/get_stats.php?id=$pendampingId");
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      final notifUrl = Uri.parse("https://$_currentIp/pendamping_api/get_notifikasi.php");
      final notifResponse = await http.get(notifUrl).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final notifData = notifResponse.statusCode == 200 ? jsonDecode(notifResponse.body)['data'] ?? [] : [];
        setState(() {
          _stats = data['data'] ?? {};
          _notifikasiList = notifData;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF19e62b);
    final String nama = _userData['nama'] ?? 'Pendamping';
    final namaPanggilan = nama.split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top App Bar
                    _buildTopBar(),
                    const SizedBox(height: 24),
                    
                    // Welcome Text
                    Text("SELAMAT DATANG", style: GoogleFonts.poppins(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text("Assalamu'alaikum, $namaPanggilan", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 24),
                    
                    // Stats Section
                    _buildStatsRow(),
                    const SizedBox(height: 32),
                    
                    // Akses Cepat
                    Text("Akses Cepat", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 16),
                    _buildAksesCepat(primaryColor),
                    const SizedBox(height: 32),
                    
                    // Update Admin
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Update Admin", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotifikasiPage(initialNotifikasi: _notifikasiList, currentIp: _currentIp))),
                          child: Text("Lihat Semua", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildUpdateAdminList(),
                  ],
                ),
              ),
            ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => JadwalPage(userData: _userData)));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => MateriPage(userData: _userData)));
          } else if (index == 3) {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilPendampingPage(userData: _userData)));
            if (result != null && result is Map) {
              setState(() {
                _userData = result;
              });
            }
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Bimbingan"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Modul"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF19e62b),
              child: Icon(Icons.person, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text("Dashboard Pendamping", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => NotifikasiPage(initialNotifikasi: _notifikasiList, currentIp: _currentIp)));
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 1)],
            ),
            child: const Icon(Icons.notifications_active, color: Colors.black87, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: "Total Peserta",
            value: "${_stats['total_catin'] ?? 24}",
            icon: Icons.people,
            trend: "+2 bulan ini",
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: "Rerata Progres",
            value: "${_stats['rerata_progres'] ?? '85%'}",
            icon: Icons.insert_chart,
            trend: "+5% dari pekan lalu",
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required String trend}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600)),
              Icon(icon, color: const Color(0xFF19e62b), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.trending_up, color: Color(0xFF19e62b), size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(trend, style: GoogleFonts.poppins(color: const Color(0xFF19e62b), fontSize: 9, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAksesCepat(Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: _buildAksesCard("Daftar\nPeserta", Icons.people, primaryColor, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => DaftarPesertaPage(userData: _userData)));
          }),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAksesCard("Materi\nGuidance", Icons.menu_book, primaryColor, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => MateriPage(userData: widget.userData)));
          }),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAksesCard("Catatan\nHarian", Icons.description, primaryColor, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => DaftarPesertaPage(userData: widget.userData, mode: 'catatan')));
          }),
        ),
      ],
    );
  }

  Widget _buildAksesCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateAdminList() {
    if (_notifikasiList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text("Belum ada update dari admin.", style: GoogleFonts.poppins(color: Colors.grey)),
        ),
      );
    }
    
    // Tampilkan max 3 di dashboard
    final displayList = _notifikasiList.take(3).toList();
    
    return Column(
      children: displayList.map((notif) {
        final judul = notif['judul'] ?? 'Pengumuman';
        final desc = notif['deskripsi'] ?? '';
        final waktu = notif['waktu'] ?? '';
        
        IconData icon = Icons.info;
        Color iconBgColor = Colors.blueAccent.withOpacity(0.15);
        Color iconColor = Colors.blueAccent;
        
        if (judul.toLowerCase().contains("jadwal")) {
          icon = Icons.calendar_month;
          iconColor = Colors.orange;
          iconBgColor = Colors.orange.withOpacity(0.15);
        } else if (judul.toLowerCase().contains("verifikasi")) {
          icon = Icons.verified;
          iconColor = Colors.green;
          iconBgColor = Colors.green.withOpacity(0.15);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildUpdateCard(
            icon: icon,
            iconColor: iconColor,
            iconBgColor: iconBgColor,
            title: judul,
            time: waktu,
            desc: desc,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUpdateCard({required IconData icon, required Color iconColor, required Color iconBgColor, required String title, required String time, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87))),
                    Text(time, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[400])),
                  ],
                ),
                const SizedBox(height: 6),
                Text(desc, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600], height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
