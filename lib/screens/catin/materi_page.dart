import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'detail_materi_page.dart';

class MateriPage extends StatefulWidget {
  final Map userData;
  const MateriPage({super.key, required this.userData});

  @override
  State<MateriPage> createState() => _MateriPageState();
}

class _MateriPageState extends State<MateriPage> {
  List daftarMateri = [];
  bool loading = true;
  String? errorMessage;
  String _currentIp = 'farel.dwirez.app';
  double progress = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchMateri();
  }

  Future<void> _fetchMateri() async {
    final prefs = await SharedPreferences.getInstance();
    _currentIp = prefs.getString('api_ip') ?? 'farel.dwirez.app';
    
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final userId = widget.userData['id'];
      final response = await http.get(
        Uri.parse("https://$_currentIp/catin_api/get_materi.php?user_id=$userId"),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            daftarMateri = data['data'];
            // Hitung Progress
            int selesai = daftarMateri.where((m) => m['is_selesai'] == true).length;
            progress = daftarMateri.isNotEmpty ? selesai / daftarMateri.length : 0.0;
            loading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'];
            loading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Gagal mengambil data dari server.";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Kesalahan koneksi: $e";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF19e62b);
    const Color bgLight = Color(0xFFF6F8F6);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Modul Pembelajaran', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: bgLight,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _fetchMateri,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.userData['role'] != 'pendamping') _buildProgressCard(primaryColor),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 30, 20, 16),
                          child: Text(
                            'Materi E-Learning',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: daftarMateri.length,
                          itemBuilder: (context, index) {
                            final materi = daftarMateri[index];
                            final bool isPendamping = widget.userData['role'] == 'pendamping';
                            final bool isLocked = isPendamping ? false : (materi['is_locked'] ?? false);
                            final bool isSelesai = isPendamping ? true : (materi['is_selesai'] ?? false);

                            return _buildMateriItem(materi, index, isLocked, isSelesai, primaryColor);
                          },
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProgressCard(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Status Bimbingan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${(progress * 100).toInt()}% Selesai', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            progress < 1.0 
              ? 'Selesaikan semua modul untuk mendapatkan sertifikat.' 
              : 'Semua modul telah selesai! Silakan ambil sertifikat.',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMateriItem(Map materi, int index, bool isLocked, bool isSelesai, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isLocked ? Colors.transparent : (isSelesai ? color.withAlpha(100) : Colors.transparent)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: isLocked ? () => _showLockedMessage() : () => _bukaMateri(materi),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isLocked ? Colors.grey[100] : (isSelesai ? color.withAlpha(20) : Colors.blue.withAlpha(20)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            isSelesai ? Icons.check_circle_rounded : (isLocked ? Icons.lock_outline_rounded : Icons.menu_book_rounded),
            color: isLocked ? Colors.grey : (isSelesai ? color : Colors.blue),
          ),
        ),
        title: Text(
          materi['judul'] ?? 'Materi ${index + 1}',
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: isLocked ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              isSelesai ? 'SELESAI' : (isLocked ? 'BELUM DIMULAI' : 'SEDANG BERJALAN'),
              style: TextStyle(
                fontSize: 10, 
                fontWeight: FontWeight.bold,
                color: isSelesai ? color : (isLocked ? Colors.grey : Colors.orange),
              ),
            ),
          ],
        ),
        trailing: Icon(
          isLocked ? Icons.lock_rounded : Icons.chevron_right_rounded,
          size: 20,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _fetchMateri, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  void _showLockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selesaikan materi sebelumnya terlebih dahulu!'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _bukaMateri(Map materi) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailMateriPage(
          materi: materi,
          userData: widget.userData,
        ),
      ),
    ).then((_) => _fetchMateri()); // Refresh saat kembali
  }
}
