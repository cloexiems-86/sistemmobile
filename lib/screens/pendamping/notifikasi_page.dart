import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotifikasiPage extends StatefulWidget {
  final List<dynamic> initialNotifikasi;
  final String currentIp;

  const NotifikasiPage({super.key, required this.initialNotifikasi, required this.currentIp});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  late List<dynamic> _notifikasi;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _notifikasi = widget.initialNotifikasi;
  }

  Future<void> _refreshNotifikasi() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse("https://${widget.currentIp}/pendamping_api/get_notifikasi.php");
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['status'] == 'success') {
          setState(() {
            _notifikasi = res['data'] ?? [];
          });
        }
      }
    } catch (e) {
      print("Error fetching notifikasi: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Pusat Notifikasi", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87))
              : const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _isLoading ? null : _refreshNotifikasi,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotifikasi,
        color: const Color(0xFF19e62b),
        child: _notifikasi.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text("Tidak ada notifikasi", style: GoogleFonts.poppins(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text("Tarik ke bawah atau tekan refresh untuk memuat ulang", style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 11)),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: _notifikasi.length,
                itemBuilder: (context, index) {
                  final notif = _notifikasi[index];
                  final judul = notif['judul'] ?? 'Pengumuman';
                  final desc = notif['deskripsi'] ?? '';
                  final waktu = notif['waktu'] ?? '';
                  
                  // Styling based on random or specific type
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

                  return _buildUpdateCard(
                    icon: icon,
                    iconColor: iconColor,
                    iconBgColor: iconBgColor,
                    title: judul,
                    time: waktu,
                    desc: desc,
                  );
                },
              ),
      ),
    );
  }

  Widget _buildUpdateCard({required IconData icon, required Color iconColor, required Color iconBgColor, required String title, required String time, required String desc}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
