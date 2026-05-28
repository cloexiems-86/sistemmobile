import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'catatan_page.dart';

class DetailPesertaPage extends StatefulWidget {
  final Map<String, dynamic> peserta;
  final Map userData;

  const DetailPesertaPage({super.key, required this.peserta, required this.userData});

  @override
  State<DetailPesertaPage> createState() => _DetailPesertaPageState();
}

class _DetailPesertaPageState extends State<DetailPesertaPage> {
  bool _isLoading = true;
  String _currentIp = 'farel.dwirez.app';
  Map<String, dynamic>? _detailData;

  @override
  void initState() {
    super.initState();
    _loadIpAndFetch();
  }

  Future<void> _loadIpAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIp = prefs.getString('api_ip') ?? 'farel.dwirez.app';
      _isLoading = true;
    });
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final catinId = widget.peserta['id'];
      final nama = widget.peserta['nama_individu'];
      final peran = widget.peserta['peran'];

      final url = Uri.parse(
        "https://$_currentIp/pendamping_api/get_detail_peserta.php?catin_id=$catinId&nama=$nama&peran=$peran"
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _detailData = data['data'];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error fetching details: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportPdfReport() async {
    setState(() => _isLoading = true);
    try {
      final pdf = pw.Document();

      final String nama = _detailData?['profil']?['nama'] ?? widget.peserta['nama_individu'] ?? 'Peserta';
      final String peran = widget.peserta['peran'] == 'suami' ? 'Suami' : 'Istri';
      final int progress = int.tryParse(_detailData?['progress']?.toString() ?? '') ?? 0;
      
      final List<dynamic> materi = _detailData?['materi'] ?? [];
      final List<dynamic> kuis = _detailData?['kuis'] ?? [];
      final Map<String, dynamic> ujian = _detailData?['ujian'] ?? {};
      final List<dynamic> riwayatUjian = ujian['riwayat'] ?? [];
      final int rataSkor = int.tryParse(ujian['rata_skor']?.toString() ?? '') ?? 0;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(35),
          build: (pw.Context context) {
            return [
              // Kemenag Header
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text("KEMENTERIAN AGAMA REPUBLIK INDONESIA", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text("KANTOR URUSAN AGAMA (KUA) KECAMATAN MOJO", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  pw.Text("KABUPATEN KEDIRI - PROVINSI JAWA TIMUR", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Jl. Raya Mojo No. 45 Mojo, Kediri", style: pw.TextStyle(fontSize: 8)),
                  pw.Divider(thickness: 1.5),
                  pw.SizedBox(height: 10),
                  pw.Text("LAPORAN PERKEMBANGAN BIMBINGAN PERKAWINAN (E-BIMWIN)", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Hasil Evaluasi Pembelajaran & Kelulusan Calon Pengantin", style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
                ],
              ),
              pw.SizedBox(height: 20),

              // Catin Info Table
              pw.Text("I. DATA CALON PENGANTIN & PENDAMPING", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                children: [
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Nama Calon Pengantin", style: pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(nama, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Peran", style: pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(peran, style: pw.TextStyle(fontSize: 9))),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Progres Belajar", style: pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("$progress% Selesai", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Pendamping Bimbingan", style: pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(widget.userData['nama'] ?? 'Pendamping KUA Mojo', style: pw.TextStyle(fontSize: 9))),
                  ]),
                ],
              ),
              pw.SizedBox(height: 18),

              // Modul Progress Table
              pw.Text("II. RIWAYAT AKSES MODUL MATERI", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("No", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Materi Pembelajaran", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Status", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Tanggal Selesai", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ...List.generate(materi.length, (idx) {
                    final m = materi[idx];
                    return pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("${idx + 1}", style: pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(m['judul'] ?? '', style: pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(m['status'] ?? '', style: pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(m['waktu'] ?? '', style: pw.TextStyle(fontSize: 9))),
                    ]);
                  }),
                ],
              ),
              pw.SizedBox(height: 18),

              // Quiz Logs Table
              pw.Text("III. RIWAYAT PENGERJAAN KUIS MATERI", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              if (kuis.isEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Text("Belum ada kuis materi yang dikerjakan.", style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("No", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Judul Kuis", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Skor Perolehan", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Tanggal Selesai", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ...List.generate(kuis.length, (idx) {
                      final k = kuis[idx];
                      return pw.TableRow(children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("${idx + 1}", style: pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(k['materi'] ?? '', style: pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("${k['nilai']} / 100", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(k['tanggal'] ?? '', style: pw.TextStyle(fontSize: 9))),
                      ]);
                    }),
                  ],
                ),
              pw.SizedBox(height: 18),

              // Final Exam Table
              pw.Text("IV. RIWAYAT EVALUASI UJIAN AKHIR", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text("Rata-rata Skor Evaluasi: $rataSkor / 100", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              if (riwayatUjian.isEmpty)
                pw.Text("Catin belum pernah mengambil Ujian Akhir.", style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic))
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Percobaan", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Skor Ujian", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Jawaban Benar/Salah", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Status Kelulusan", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Tanggal Ujian", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ...List.generate(riwayatUjian.length, (idx) {
                      final r = riwayatUjian[idx];
                      return pw.TableRow(children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Ke-${riwayatUjian.length - idx}", style: pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("${r['skor']} / 100", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("B: ${r['benar']} | S: ${r['salah']}", style: pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(r['status'] ?? '', style: pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(r['tanggal'] ?? '', style: pw.TextStyle(fontSize: 9))),
                      ]);
                    }),
                  ],
                ),
              pw.SizedBox(height: 45),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text("Kepala KUA Kecamatan Mojo", style: pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 45),
                      pw.Text("_______________________", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text("NIP. 197508122003121002", style: pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text("Pendamping Bimbingan", style: pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 45),
                      pw.Text(widget.userData['nama'] ?? 'Pendamping KUA', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                      pw.Text("NIP. ${widget.userData['nip'] ?? widget.userData['username'] ?? '-'}", style: pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              )
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      setState(() => _isLoading = false);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewPage(
            pdfBytes: bytes,
            fileName: 'Laporan_Bimwin_${nama.replaceAll(' ', '_')}.pdf',
          ),
        ),
      );
    } catch (e) {
      print("Error generating PDF: $e");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengekspor laporan PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF19e62b);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Progres Bimbingan Catin",
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isLoading 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87))
              : const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _isLoading ? null : _fetchDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _fetchDetails,
              color: primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header card
                    _buildProfileCard(primaryColor),
                    const SizedBox(height: 20),

                    // Stats row showing progress & sessions
                    _buildStatsRow(primaryColor),
                    const SizedBox(height: 24),

                    // Perkembangan Modul List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Perkembangan Modul", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Icon(Icons.menu_book, color: Colors.grey[400], size: 18),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildModulList(primaryColor),
                    const SizedBox(height: 24),

                    // Pengerjaan Kuis
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Pengerjaan Kuis", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Icon(Icons.quiz_outlined, color: Colors.grey[400], size: 18),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildKuisList(primaryColor),
                    const SizedBox(height: 24),

                    // Riwayat Ujian Akhir (Lulus / Remedial / Tidak Lulus)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Evaluasi Ujian Akhir", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Icon(Icons.assignment_outlined, color: Colors.grey[400], size: 18),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildEvaluasiCard(primaryColor),
                    const SizedBox(height: 32),

                    // Fungsional Konsultasi & Ekspor PDF
                    _buildActionButtons(primaryColor),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileCard(Color primaryColor) {
    final profil = _detailData?['profil'] ?? {};
    final String nama = profil['nama'] ?? widget.peserta['nama_individu'] ?? 'Peserta';
    final int progress = int.tryParse(_detailData?['progress']?.toString() ?? '') ?? 
                         int.tryParse(widget.peserta['progress_individu']?.toString() ?? '') ?? 0;
    final bool isSelesai = progress >= 100;
    final String role = widget.peserta['peran'] == 'suami' ? 'Suami' : 'Istri';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE8F5E9),
            child: Icon(
              widget.peserta['peran'] == 'suami' ? Icons.face : Icons.face_4,
              color: primaryColor,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nama, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                Text(
                  "Calon Pengantin ($role)",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelesai ? Colors.blue.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isSelesai ? "Selesai Bimbingan" : "Status: Aktif",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelesai ? Colors.blue : primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Color primaryColor) {
    final int progress = int.tryParse(_detailData?['progress']?.toString() ?? '') ?? 
                         int.tryParse(widget.peserta['progress_individu']?.toString() ?? '') ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("MODUL MATERI", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("$progress%", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  progress >= 100 ? "Selesai" : "Progres",
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey[100],
              color: progress >= 100 ? Colors.blue : primaryColor,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulList(Color primaryColor) {
    final List<dynamic> materi = _detailData?['materi'] ?? [];

    if (materi.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text("Belum ada data modul.", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
        ),
      );
    }

    return Column(
      children: List.generate(materi.length, (index) {
        final m = materi[index];
        final bool isCompleted = m['status'] == 'Selesai';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isCompleted ? Colors.transparent : primaryColor.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleted ? Icons.menu_book : Icons.lock_open,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m['judul'] ?? 'Materi', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 2),
                    Text(
                      isCompleted ? "Selesai: ${m['waktu']}" : "Belum mulai dipelajari",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isCompleted ? Colors.grey[500] : primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted ? primaryColor : Colors.grey[300],
                size: 22,
              )
            ],
          ),
        );
      }),
    );
  }

  Widget _buildKuisList(Color primaryColor) {
    final List<dynamic> kuis = _detailData?['kuis'] ?? [];

    if (kuis.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Center(
          child: Text("Belum ada kuis yang selesai dikerjakan.", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
        ),
      );
    }

    return Column(
      children: List.generate(kuis.length, (index) {
        final k = kuis[index];
        final int nilai = int.tryParse(k['nilai']?.toString() ?? '') ?? 0;
        final bool isLulus = nilai >= 70;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isLulus ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLulus ? Icons.verified : Icons.error_outline,
                  color: isLulus ? Colors.green : Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Kuis: ${k['materi']}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 2),
                    Text(
                      "Pengerjaan: ${k['tanggal']}",
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$nilai/100",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: isLulus ? Colors.green : Colors.orange),
                  ),
                  Text(
                    isLulus ? "LULUS" : "REMEDIAL",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 9, color: isLulus ? Colors.green : Colors.orange),
                  ),
                ],
              )
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEvaluasiCard(Color primaryColor) {
    final Map<String, dynamic> ujian = _detailData?['ujian'] ?? {};
    final int rataSkor = int.tryParse(ujian['rata_skor']?.toString() ?? '') ?? 0;
    final List<dynamic> riwayat = ujian['riwayat'] ?? [];

    if (riwayat.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Center(
          child: Text("Catin belum pernah mengambil Ujian Evaluasi.", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Rata-rata Skor Ujian", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: rataSkor >= 70 ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  rataSkor >= 70 ? "Kelulusan: Lulus" : "Kelulusan: Remedial",
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: rataSkor >= 70 ? Colors.green : Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("$rataSkor", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text("/100", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          Text("RIWAYAT UJIAN AKHIR", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Column(
            children: List.generate(riwayat.length, (idx) {
              final r = riwayat[idx];
              final bool isLulus = r['status'] == 'Lulus';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Skor Ujian: ${r['skor']}/100", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Text(
                          "Tanggal: ${r['tanggal']} | B: ${r['benar']} S: ${r['salah']}",
                          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLulus ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isLulus ? "LULUS" : "REMEDIAL",
                        style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: isLulus ? Colors.green : Colors.orange),
                      ),
                    )
                  ],
                ),
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildActionButtons(Color primaryColor) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CatatanPage(
                    peserta: widget.peserta,
                    userData: widget.userData,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.forum_outlined, color: Colors.white, size: 20),
            label: Text("Konsultasi Bimbingan", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _exportPdfReport,
            icon: const Icon(Icons.download, color: Colors.black87, size: 20),
            label: Text("Ekspor Laporan PDF", style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.black12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class PdfPreviewPage extends StatelessWidget {
  final List<int> pdfBytes;
  final String fileName;

  const PdfPreviewPage({super.key, required this.pdfBytes, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(fileName, style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SfPdfViewer.memory(
        Uint8List.fromList(pdfBytes),
      ),
    );
  }
}
