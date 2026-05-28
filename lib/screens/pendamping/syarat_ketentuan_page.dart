import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SyaratKetentuanPage extends StatelessWidget {
  const SyaratKetentuanPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF19e62b);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Syarat & Ketentuan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Handbook Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.gavel, color: primaryColor, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "PANDUAN HUKUM & ETIKA",
                          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Syarat & Ketentuan Pendamping",
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Berlaku per Mei 2026",
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Content Sections
            _buildSectionTitle("1. PENDAHULUAN"),
            _buildSectionBody(
              "Selamat datang di Sistem Aplikasi E-Bimwin KUA Kecamatan Mojo. Dokumen Syarat & Ketentuan ini mengatur hak, kewajiban, dan tata tertib bagi seluruh Pendamping (Konselor/Fasilitator) resmi yang terdaftar untuk melaksanakan bimbingan perkawinan kepada Calon Pengantin (Catin) melalui media elektronik mobile."
            ),
            
            _buildSectionTitle("2. TANGGUNG JAWAB PENDAMPING"),
            _buildSectionBody(
              "Sebagai Pendamping terdaftar, Anda berkewajiban untuk:\n"
              "• Memberikan bimbingan perkawinan secara profesional, objektif, dan berlandaskan pada syariat serta regulasi Kementerian Agama.\n"
              "• Memantau perkembangan (progress) materi e-learning yang diselesaikan oleh Catin secara berkala.\n"
              "• Memberikan catatan bimbingan atau masukan yang membangun di halaman Catatan Catin sebagai bahan evaluasi sidang pranikah.\n"
              "• Hadir tepat waktu pada sesi bimbingan tatap muka sesuai jadwal yang ditetapkan Admin KUA."
            ),

            _buildSectionTitle("3. PERLINDUNGAN PRIVASI DATA CATIN"),
            _buildSectionBody(
              "Keamanan data Calon Pengantin adalah prioritas utama. Anda dilarang keras untuk:\n"
              "• Menyebarluaskan, menyalin, atau menyalahgunakan dokumen penting Catin (seperti KTP, Kartu Keluarga, alamat email, atau nomor HP) yang diakses melalui aplikasi.\n"
              "• Membagikan kredensial akun login Pendamping Anda kepada pihak ketiga mana pun tanpa persetujuan tertulis dari Kepala KUA Kecamatan Mojo."
            ),

            _buildSectionTitle("4. PENGGUNAAN APLIKASI YANG SAH"),
            _buildSectionBody(
              "Aplikasi E-Bimwin hanya boleh digunakan untuk tujuan fasilitasi bimbingan resmi perkawinan. Segala bentuk manipulasi data statistik bimbingan Catin, pengisian catatan fiktif, atau penyalahgunaan fitur komunikasi dalam aplikasi akan dikenakan sanksi pencabutan hak akses sebagai Pendamping resmi KUA."
            ),

            _buildSectionTitle("5. PERUBAHAN SYARAT & KETENTUAN"),
            _buildSectionBody(
              "KUA Kecamatan Mojo berhak melakukan pembaruan pada syarat dan ketentuan ini sewaktu-waktu guna menyelaraskan dengan kebijakan baru Kementerian Agama RI. Setiap perubahan akan diinformasikan secara langsung melalui menu Update Pengumuman Admin di dashboard aplikasi."
            ),

            const SizedBox(height: 30),

            // Agreement Check Footer matching professional presentation style
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified, color: primaryColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Persetujuan Dokumen",
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green[900]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Dengan tetap masuk dan menggunakan layanan aplikasi E-Bimwin ini, Anda secara hukum menyatakan setuju dan tunduk pada seluruh ketentuan etika pendampingan KUA Mojo.",
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.green[800], height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildSectionBody(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], height: 1.6),
    );
  }
}
