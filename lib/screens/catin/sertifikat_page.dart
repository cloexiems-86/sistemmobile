import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'sertifikat_view_page.dart';
import 'ujian_page.dart';

class SertifikatPage extends StatefulWidget {
  final Map? userData;
  const SertifikatPage({super.key, this.userData});

  @override
  State<SertifikatPage> createState() => _SertifikatPageState();
}

class _SertifikatPageState extends State<SertifikatPage> {
  bool isLoading = true;
  bool isLulus = false;
  String? urlSertifikat;
  String? urlDownload;
  String? message;
  int skor = 0;
  int totalMateri = 0;
  int materiSelesai = 0;
  String _currentIp = 'farel.dwirez.app';

  @override
  void initState() {
    super.initState();
    _fetchSertifikat();
  }

  Future<void> _fetchSertifikat() async {
    final prefs = await SharedPreferences.getInstance();
    _currentIp = prefs.getString('api_ip') ?? 'farel.dwirez.app';
    
    try {
      final userId = widget.userData?['id'] ?? '1';
      final namaAktif = widget.userData?['nama_aktif'] ?? widget.userData?['nama'] ?? '';
      final peran = (namaAktif == widget.userData?['nama_suami']) ? 'suami' : 'istri';
      // Gunakan HTTPS agar lebih aman dan sesuai dengan API Laravel
      final response = await http.get(
        Uri.parse("https://$_currentIp/catin_api/get_sertifikat.php?user_id=$userId&nama_peserta=${Uri.encodeComponent(namaAktif)}&peran=$peran"),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        int parsedSkor = 0;
        
        // Cek apakah ada skor lokal (dari ujian terakhir di perangkat ini)
        String? localScore = prefs.getString('last_exam_score_$userId');
        if (localScore != null) {
          parsedSkor = int.tryParse(localScore) ?? 0;
        } else if (data['skor'] != null) {
          parsedSkor = int.tryParse(data['skor'].toString()) ?? 0;
        }
        
        bool apiIsLulus = data['is_lulus'] ?? false;
        
        setState(() {
          skor = parsedSkor;
          isLulus = apiIsLulus && (skor >= 70);
          String? urlS = data['url_sertifikat'];
          if (urlS != null && urlS.isNotEmpty && !urlS.startsWith('http')) {
            if (urlS.startsWith('/')) {
              urlS = "https://$_currentIp$urlS";
            } else {
              // Misal balikan API adalah "catin_api/file.pdf" atau "sertifikat/file.pdf"
              urlS = urlS.startsWith('catin_api') ? "https://$_currentIp/$urlS" : "https://$_currentIp/catin_api/$urlS";
            }
          }
          urlSertifikat = urlS;

          String? urlD = data['url_download'];
          if (urlD != null && urlD.isNotEmpty && !urlD.startsWith('http')) {
            if (urlD.startsWith('/')) {
              urlD = "https://$_currentIp$urlD";
            } else {
              urlD = urlD.startsWith('catin_api') ? "https://$_currentIp/$urlD" : "https://$_currentIp/catin_api/$urlD";
            }
          }
          urlDownload = urlD;

          message = data['message'];
          totalMateri = data['total_materi'] ?? 0;
          materiSelesai = data['materi_selesai'] ?? 0;
          isLoading = false;
        });
      } else {
        setState(() {
          message = "Gagal memuat status kelulusan (Error: ${response.statusCode}).";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        message = "Kesalahan koneksi: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF19e62b);
    const bgLight = Color(0xFFF6F8F6);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Sertifikat Bimwin', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: bgLight,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    _buildStatusIcon(isLulus),
                    const SizedBox(height: 32),
                    Text(
                      isLulus ? "Selamat! Anda Lulus" : "Tidak Lulus (remedial ujian lagi)",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        isLulus 
                          ? "Anda telah menyelesaikan seluruh rangkaian Bimbingan Perkawinan dengan hasil yang memuaskan."
                          : (message ?? "Selesaikan semua materi dan raih nilai minimal 70 untuk mendapatkan sertifikat."),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 48),
                    if (isLulus)
                      _buildCertificatePreview()
                    else
                      _buildRequirementInfo(),
                    const SizedBox(height: 40),
                    if (isLulus)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                             if (urlSertifikat != null) {
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(
                                   builder: (context) => SertifikatViewPage(
                                     pdfUrl: urlSertifikat!,
                                     downloadUrl: urlDownload ?? urlSertifikat!,
                                     title: "Sertifikat Bimwin",
                                   ),
                                 ),
                               );
                             }
                          },
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          label: const Text("LIHAT & UNDUH SERTIFIKAT", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UjianPage(userData: widget.userData ?? {}),
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text("ULANGI UJIAN (REMEDIAL)", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusIcon(bool lulus) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: (lulus ? Colors.green : Colors.red).withAlpha(30),
        shape: BoxShape.circle,
      ),
      child: Icon(
        lulus ? Icons.workspace_premium_rounded : Icons.cancel_rounded,
        size: 80,
        color: lulus ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _buildCertificatePreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Opacity(
              opacity: 0.1,
              child: Image.network(
                "https://upload.wikimedia.org/wikipedia/commons/thumb/d/db/Garuda_Pancasila_Coat_of_Arms_of_Indonesia.svg/1200px-Garuda_Pancasila_Coat_of_Arms_of_Indonesia.svg.png",
                height: 120,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("SERTIFIKAT BIMBINGAN PERKAWINAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Spacer(),
                Text("Diberikan kepada:", style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text("Peserta E-Learning KUA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("No: KUA/BIMWIN/2026/001", style: TextStyle(fontSize: 8)),
                    Icon(Icons.qr_code, size: 40),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withAlpha(100)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange),
              SizedBox(width: 12),
              Text("Syarat Sertifikat", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildReqItem(
            Icons.check_circle, 
            "Menyelesaikan semua materi ($materiSelesai/$totalMateri)", 
            materiSelesai >= totalMateri && totalMateri > 0
          ),
          _buildReqItem(
            Icons.check_circle, 
            "Mengerjakan kuis setiap materi", 
            materiSelesai >= totalMateri && totalMateri > 0
          ),
          _buildReqItem(
            Icons.stars, 
            "Nilai Ujian Akhir minimal 70 (Skor: $skor)", 
            skor >= 70
          ),
        ],
      ),
    );
  }

  Widget _buildReqItem(IconData icon, String text, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: done ? Colors.green : Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 13, color: done ? Colors.black87 : Colors.grey)),
        ],
      ),
    );
  }
}