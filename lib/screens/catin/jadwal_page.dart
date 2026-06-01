import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// WAJIB IMPORT API SERVICE YANG BARU KITA BUAT
import '../services/api_service.dart';

class JadwalPage extends StatefulWidget {
  final Map userData;
  const JadwalPage({super.key, required this.userData});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  bool loading = true;
  List<dynamic> daftarJadwal = [];
  String? errorMessage;
  String _currentIp = 'farel.dwirez.app';

  @override
  void initState() {
    super.initState();
    _initAndFetch();
  }

  Future<void> _initAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIp = prefs.getString('api_ip') ?? 'farel.dwirez.app';
    });
    await ambilJadwal();
  }

  Future<void> ambilJadwal() async {
    if (mounted) setState(() => loading = true);
    try {
      String userId = widget.userData['id']?.toString() ?? '';
      var url = Uri.parse("https://$_currentIp/catin_api/get_jadwal.php?user_id=$userId");
      var response = await http.get(url).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          daftarJadwal = data is List ? data : (data['data'] ?? []);
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
        errorMessage = 'Gagal memuat jadwal: $e';
        loading = false;
      });
    }
  }

  Future<void> _prosesAbsensi(String jadwalId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
            ),
            SizedBox(width: 15),
            Text('Mencatat kehadiran...'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blueGrey,
      ),
    );

    String userId = widget.userData['id']?.toString() ?? '';
    String peserta = widget.userData['peserta']?.toString() ?? '';

    final result = await ApiService.submitAbsensi(
      userId,
      jadwalId,
      peserta,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ ${result['message']}"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      ambilJadwal(); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ ${result['message']}"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF19e62b);
    const Color bgLight = Color(0xFFF6F8F6);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Jadwal Bimbingan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: bgLight,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: ambilJadwal,
        color: primaryColor,
        child: loading
            ? const Center(child: CircularProgressIndicator(color: primaryColor))
            : errorMessage != null
                ? _buildErrorState()
                : daftarJadwal.isEmpty
                    ? _buildEmptyState()
                    : _buildJadwalList(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(errorMessage ?? 'Terjadi kesalahan', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: ambilJadwal,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF19e62b)),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Belum ada jadwal bimbingan', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildJadwalList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      itemCount: daftarJadwal.length,
      itemBuilder: (context, index) {
        final jadwal = daftarJadwal[index];
        return _buildJadwalCard(jadwal);
      },
    );
  }

  Widget _buildJadwalCard(Map<String, dynamic> jadwal) {
    const Color primaryColor = Color(0xFF19e62b);
    
    // 1. CEK STATUS DARI DATABASE (Selesai/Batal)
    String status = (jadwal['status'] ?? 'mendatang').toString().toLowerCase();
    bool isSelesaiAtauBatal = (status == 'selesai' || status == 'batal');
    
    // 2. CEK WAKTU NYATA (Apakah sudah terlewat hari dan jamnya)
    bool isTerlewat = _isJadwalTerlewat(jadwal['tanggal'], jadwal['jam']);
    
    // 3. KEPUTUSAN FINAL TOMBOL ABSENSI
    bool isDitutup = isSelesaiAtauBatal || isTerlewat;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 15, offset: Offset(0, 5)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showJadwalDetail(jadwal),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 80,
                    color: primaryColor.withAlpha(20),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getDay(jadwal['tanggal']),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getDate(jadwal['tanggal']),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                        Text(
                          _getMonth(jadwal['tanggal']),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  jadwal['judul'] ?? 'Sesi Bimbingan',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildStatusChip(status),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.access_time_filled, jadwal['jam'] ?? '09:00 - 11:00', Colors.orange),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.location_on, jadwal['tempat'] ?? 'KUA Mojo', Colors.teal),
                          const SizedBox(height: 12),
                          const Divider(),
                          
                          // TAMPILAN TOMBOL ABSEN
                          isDitutup
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Sesi / Waktu Telah Ditutup',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      String jadwalId = jadwal['id']?.toString() ?? '';
                                      _prosesAbsensi(jadwalId);
                                    },
                                    icon: const Icon(Icons.touch_app, size: 18),
                                    label: const Text(
                                      'Absen Kehadiran',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showJadwalDetail(Map<String, dynamic> jadwal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(jadwal['judul'] ?? 'Detail Jadwal', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.calendar_today, jadwal['tanggal'] ?? '-', Colors.green),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.access_time, jadwal['jam'] ?? '-', Colors.orange),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, jadwal['tempat'] ?? '-', Colors.teal),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person, jadwal['narasumber'] ?? 'Petugas KUA', Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Deskripsi:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(jadwal['deskripsi'] ?? 'Tidak ada deskripsi tambahan untuk sesi ini.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    String label;
    
    switch (status.toLowerCase()) {
      case 'selesai':
        chipColor = Colors.teal;
        label = 'Selesai';
        break;
      case 'batal':
        chipColor = Colors.red;
        label = 'Batal';
        break;
      default:
        chipColor = Colors.orange;
        label = 'Mendatang';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: chipColor),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  String _getDay(String? dateStr) {
    if (dateStr == null) return 'Sen';
    try {
      DateTime dt = DateTime.parse(dateStr);
      List<String> days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      return days[dt.weekday - 1];
    } catch (e) {
      return 'Hari';
    }
  }

  String _getDate(String? dateStr) {
    if (dateStr == null) return '01';
    try {
      DateTime dt = DateTime.parse(dateStr);
      return dt.day.toString().padLeft(2, '0');
    } catch (e) {
      return '??';
    }
  }

  String _getMonth(String? dateStr) {
    if (dateStr == null) return 'Jan';
    try {
      DateTime dt = DateTime.parse(dateStr);
      List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return months[dt.month - 1];
    } catch (e) {
      return 'Bulan';
    }
  }

  // ==============================================================
  // FUNGSI BARU (PERBAIKAN ANTI-BADAI): Logika Waktu Nyata 
  // Menangani salah ketik admin (pakai titik bukan titik dua)
  // ==============================================================
  bool _isJadwalTerlewat(String? tanggalStr, String? jamStr) {
    if (tanggalStr == null) return false;
    try {
      String endTimeStr = "23:59"; 
      if (jamStr != null && jamStr.contains('-')) {
        endTimeStr = jamStr.split('-')[1].trim(); 
      } else if (jamStr != null) {
        endTimeStr = jamStr.trim();
      }

      // FITUR PENYELAMAT: Ubah tanda titik (.) menjadi titik dua (:)
      // Jika admin KUA ngetik "05.00", akan diubah jadi "05:00" agar sistem paham.
      endTimeStr = endTimeStr.replaceAll('.', ':');

      List<String> timeParts = endTimeStr.split(':');
      int hour = 23;
      int minute = 59;
      
      if (timeParts.length >= 2) {
        hour = int.tryParse(timeParts[0]) ?? 23;
        minute = int.tryParse(timeParts[1]) ?? 59;
      }

      // Gabungkan Tanggal Jadwal dengan Jam Akhir
      DateTime date = DateTime.parse(tanggalStr);
      DateTime scheduleEnd = DateTime(date.year, date.month, date.day, hour, minute);
      
      // Ambil waktu saat ini
      DateTime now = DateTime.now();

      // Jika waktu saat ini sudah melewati batas akhir jadwal, return true
      return now.isAfter(scheduleEnd);
    } catch (e) {
      return false;
    }
  }
}