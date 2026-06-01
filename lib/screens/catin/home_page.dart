import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'materi_page.dart';
import 'ujian_page.dart';
import 'sertifikat_page.dart';
import 'konsultasi_page.dart';
import 'detail_catin_page.dart';
import 'jadwal_page.dart';
import 'notifikasi_page.dart';
import 'detail_materi_page.dart';

class HomePage extends StatefulWidget {
  final Map userData;
  const HomePage({super.key, required this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  Map<String, dynamic> dashboardData = {};
  String? errorMessage;
  String _currentIp = 'farel.dwirez.app';

  @override
  void initState() {
    super.initState();
    _initAndFetch();
  }

  Future<void> _initAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _currentIp = prefs.getString('api_ip') ?? 'farel.dwirez.app';
    await ambilDashboard();
  }

  Future<void> ambilDashboard() async {
    if (mounted) setState(() => loading = true);
    try {
      String userId = widget.userData['id']?.toString() ?? '';
      String namaAktif = widget.userData['nama_aktif'] ?? widget.userData['nama'] ?? 'User';
      
      // Fetch Dashboard Data
      var url = Uri.parse("https://$_currentIp/catin_api/get_dashboard.php?user_id=$userId&nama_peserta=$namaAktif");
      var response = await http.get(url).timeout(const Duration(seconds: 10));
      
      // Fetch Announcements (Personalized)
      var urlAnn = Uri.parse("https://$_currentIp/catin_api/get_pengumuman.php?user_id=$userId&nama_aktif=$namaAktif");
      var responseAnn = await http.get(urlAnn).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var dataAnn = responseAnn.statusCode == 200 ? jsonDecode(responseAnn.body) : {'data': []};
        
        setState(() {
          dashboardData = data['data'] ?? data;
          dashboardData['pengumuman'] = dataAnn['data'];
          loading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Error: ${response.statusCode}';
          loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        loading = false;
      });
    }
  }

  void _showPengumumanSheet(BuildContext context) {
    List announcements = dashboardData['pengumuman'] ?? [];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pengumuman KUA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            announcements.isEmpty
                ? const Expanded(child: Center(child: Text('Tidak ada pengumuman saat ini.')))
                : Expanded(
                    child: ListView.builder(
                      itemCount: announcements.length,
                      itemBuilder: (context, index) {
                        var ann = announcements[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: Colors.grey[100],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            leading: const Icon(Icons.info_outline, color: Color(0xFF19e62b)),
                            title: Text(ann['judul'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(ann['isi'] ?? ''),
                            trailing: Text(ann['tgl_post']?.toString().split(' ')[0] ?? '', style: const TextStyle(fontSize: 10)),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      // Sudah di Beranda
      return;
    } else if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => MateriPage(userData: widget.userData))).then((_) => ambilDashboard());
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => JadwalPage(userData: widget.userData))).then((_) => ambilDashboard());
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => DetailCatinPage(userData: widget.userData))).then((_) => ambilDashboard());
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature akan segera hadir!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String namaAktif = widget.userData['nama_aktif'] ?? widget.userData['nama'] ?? 'Ahmad & Siti';
    const Color primaryColor = Color(0xFF19e62b);
    const Color bgLight = Color(0xFFF6F8F6);

    if (loading) {
      return const Scaffold(
        backgroundColor: bgLight,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: primaryColor.withAlpha(40),
              child: const Icon(Icons.person, size: 20, color: Color(0xFF19e62b)),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Beranda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('E-Learning KUA', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        backgroundColor: bgLight,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 24),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotifikasiPage(userData: widget.userData)),
                ).then((_) => ambilDashboard()), // Refresh after back
              ),
              if (dashboardData['pengumuman'] != null && (dashboardData['pengumuman'] as List).isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: ambilDashboard,
        color: primaryColor,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Hero Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, $namaAktif! 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.1),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Selamat pagi, calon pengantin. Semangat melengkapi persiapan ibadah terpanjang kalian.',
                      style: TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: primaryColor, size: 16),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'KUA Kecamatan Mojo, Kediri',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Progress Card
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0D000000), blurRadius: 20, offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_stories, color: primaryColor, size: 24),
                            const SizedBox(width: 12),
                            const Text('Progres Pembelajaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Text(
                          '${dashboardData['progress']?['persentase'] ?? 0}%',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: (dashboardData['progress']?['persentase'] ?? 0) / 100,
                        minHeight: 12,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(primaryColor),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildProgressStat(Icons.menu_book, '${dashboardData['progress']?['materi_dibaca'] ?? 0}', 'Materi', primaryColor),
                        _buildProgressStat(Icons.quiz, '${dashboardData['progress']?['kuis_selesai'] ?? 0}', 'Kuis', Colors.orange),
                        _buildProgressStat(Icons.check_circle, '${dashboardData['progress']?['ujian_selesai'] ?? 0}', 'Ujian', Colors.teal),
                      ],
                    ),
                  ],
                ),
              ),
              // Jadwal Section Header
              if (dashboardData['jadwal_terdekat'] != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jadwal Terdekat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JadwalPage(userData: widget.userData))),
                        child: const Text('Lihat Semua'),
                      ),
                    ],
                  ),
                ),
                // Jadwal Card
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JadwalPage(userData: widget.userData))),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Color(0x1A000000), blurRadius: 20),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Jadwal image background
                        Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [primaryColor, primaryColor.withAlpha(180), const Color(0xFF0D7A17)],
                            ),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Color(0xB3000000)],
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Tatap Muka', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Jadwal content
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dashboardData['jadwal_terdekat']?['judul'] ?? 'Sesi Bimbingan',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.calendar_today, '${dashboardData['jadwal_terdekat']?['tanggal'] ?? ''} • ${dashboardData['jadwal_terdekat']?['jam'] ?? ''}'),
                              _buildInfoRow(Icons.location_on, dashboardData['jadwal_terdekat']?['tempat'] ?? 'KUA'),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.black87,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JadwalPage(userData: widget.userData))),
                                      child: const Text('Lihat Detail'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.share_outlined),
                                    onPressed: () {
                                      final title = dashboardData['jadwal_terdekat']?['judul'] ?? 'Sesi Bimbingan';
                                      final date = dashboardData['jadwal_terdekat']?['tanggal'] ?? '';
                                      final time = dashboardData['jadwal_terdekat']?['jam'] ?? '';
                                      final place = dashboardData['jadwal_terdekat']?['tempat'] ?? '';
                                      final shareText = "Jadwal Bimbingan Catin: $title\nTanggal: $date ($time)\nTempat: $place";
                                      
                                      Clipboard.setData(ClipboardData(text: shareText));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Info jadwal disalin ke papan klip!'),
                                          backgroundColor: Colors.blue,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jadwal Bimbingan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JadwalPage(userData: widget.userData))),
                        child: const Text('Lihat Jadwal'),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_available, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('Belum ada jadwal bimbingan terdekat', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
              // Menu Cepat
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Menu Cepat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      // PERBAIKAN: Mengubah rasio dari 1 menjadi 0.75 agar punya ruang vertikal lebih tinggi untuk teks
                      childAspectRatio: 0.75, 
                      children: [
                        _buildMenuButton(Icons.menu_book_outlined, 'Materi', primaryColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MateriPage(userData: widget.userData))).then((_) => ambilDashboard())),
                        _buildMenuButton(Icons.quiz_outlined, 'Ujian', Colors.orange, () {
                          int total = dashboardData['progress']?['total_materi'] ?? 0;
                          int selesai = dashboardData['progress']?['kuis_selesai'] ?? 0;
                          if (selesai < total && total > 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Selesaikan semua materi dan kuis terlebih dahulu!'),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => UjianPage(userData: widget.userData))).then((_) => ambilDashboard());
                          }
                        }),
                        _buildMenuButton(Icons.verified_user_outlined, 'Sertifikat', Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => SertifikatPage(userData: widget.userData))).then((_) => ambilDashboard())),
                        _buildMenuButton(Icons.chat_bubble_outline, 'Konsultasi', Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => KonsultasiPage(userData: widget.userData))).then((_) => ambilDashboard())),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Materi Terbaru Section
                    if (dashboardData['materi_terbaru'] != null && (dashboardData['materi_terbaru'] as List).isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Materi Terbaru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MateriPage(userData: widget.userData))),
                            child: const Text('Lihat Semua'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: (dashboardData['materi_terbaru'] as List).length,
                          itemBuilder: (context, index) {
                            var materi = dashboardData['materi_terbaru'][index];
                            bool isVideo = materi['file']?.toString().toLowerCase().endsWith('.mp4') ?? false;
                            
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => DetailMateriPage(materi: materi, userData: widget.userData))
                              ).then((_) => ambilDashboard()),
                              child: Container(
                                width: 280,
                                margin: const EdgeInsets.only(right: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 10)],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: isVideo ? Colors.red.withAlpha(20) : Colors.blue.withAlpha(20),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isVideo ? Icons.play_circle_fill : Icons.description,
                                        color: isVideo ? Colors.red : Colors.blue,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            materi['judul'] ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            materi['deskripsi'] ?? '',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_stories), label: 'Kursus'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Jadwal'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildProgressStat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildMenuButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          // PERBAIKAN: Membungkus Text dengan FittedBox agar tidak overflow jika layar HP kecil
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}