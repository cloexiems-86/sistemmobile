import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PusatBantuanPage extends StatefulWidget {
  const PusatBantuanPage({super.key});

  @override
  State<PusatBantuanPage> createState() => _PusatBantuanPageState();
}

class _PusatBantuanPageState extends State<PusatBantuanPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _faqs = [
    {
      'question': 'Bagaimana cara melihat progres pembelajaran Catin?',
      'answer': 'Anda dapat membuka menu "Daftar Peserta" pada dashboard utama. Di sana akan ditampilkan seluruh Catin yang berada di bawah bimbingan Anda beserta persentase modul materi yang telah mereka selesaikan secara real-time.',
      'category': 'Bimbingan',
    },
    {
      'question': 'Di mana saya bisa menambahkan catatan bimbingan?',
      'answer': 'Masuk ke menu "Daftar Peserta", pilih salah satu Catin yang ingin Anda berikan masukan, lalu klik tombol "Catatan". Anda dapat menulis umpan balik atau bimbingan khusus pada kolom input chat lalu klik "Simpan". Catatan akan langsung tersimpan di database.',
      'category': 'Bimbingan',
    },
    {
      'question': 'Mengapa daftar bimbingan Catin saya tidak muncul?',
      'answer': 'Daftar Catin hanya akan muncul jika Admin KUA sudah menjadwalkan bimbingan dan menetapkan Anda sebagai Pendamping resmi untuk pasangan Catin tersebut pada tanggal bimbingan yang telah ditentukan di sistem web admin.',
      'category': 'Masalah Teknis',
    },
    {
      'question': 'Apakah saya bisa mengganti kata sandi login?',
      'answer': 'Tentu saja. Anda dapat masuk ke halaman "Profil & Pengaturan", pilih "Edit Profil", lalu isi kata sandi baru Anda pada kolom "GANTI PASSWORD (OPSIONAL)". Jika tidak ingin mengganti password, cukup kosongkan kolom tersebut.',
      'category': 'Akun & Keamanan',
    },
    {
      'question': 'Bagaimana cara melihat jadwal bimbingan tatap muka?',
      'answer': 'Jadwal bimbingan aktif Anda dapat dipantau langsung melalui tab "Bimbingan/Jadwal" di navigasi bawah aplikasi. Jadwal yang ditampilkan mencakup topik bimbingan, tanggal pelaksanaan, waktu/sesi, serta lokasi bimbingan.',
      'category': 'Jadwal',
    },
    {
      'question': 'Siapa yang harus dihubungi jika ada kesalahan data Catin?',
      'answer': 'Jika terdapat kesalahan administrasi atau pencatatan data diri pasangan Catin, Anda dapat segera berkoordinasi dengan petugas IT KUA Kecamatan Mojo.',
      'category': 'Dukungan',
    },
  ];

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF19e62b);
    
    final filteredFaqs = _faqs.where((faq) {
      final query = _searchQuery.toLowerCase();
      return faq['question']!.toLowerCase().contains(query) ||
             faq['answer']!.toLowerCase().contains(query) ||
             faq['category']!.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Pusat Bantuan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Green Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Halo Pendamping KUA,",
                    style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Ada yang bisa kami bantu hari ini?",
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Cari panduan bimbingan, jadwal...",
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: primaryColor),
                        suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // FAQs List Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("PERTANYAAN POPULER", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.1)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      "${filteredFaqs.length} Artikel",
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (filteredFaqs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40.0, bottom: 40.0),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text("Pencarian tidak ditemukan", style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: filteredFaqs.length,
                itemBuilder: (context, index) {
                  final faq = filteredFaqs[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[100]!),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 6, offset: const Offset(0, 3))
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.help_outline, color: primaryColor, size: 20),
                        ),
                        title: Text(
                          faq['question']!,
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                        expandedAlignment: Alignment.topLeft,
                        children: [
                          Text(
                            faq['answer']!,
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], height: 1.5),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Chip(
                              label: Text(faq['category']!, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                              backgroundColor: Colors.grey[100],
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),


            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
